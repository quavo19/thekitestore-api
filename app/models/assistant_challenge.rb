require "digest"
require "securerandom"

# Service-only browser bridge. Ticket/code are never returned to a chat/model.
class AssistantChallenge < ApplicationRecord
  belongs_to :user, optional: true

  def self.fingerprint(user)
    Digest::SHA256.hexdigest([user.email, user.encrypted_password, user.role_id, user.blocked?].join("\0"))
  end

  def self.authenticate!(action:, credentials:, context:)
    raise AssistantDelegation::Denied unless ENV['ASSISTANT_IDENTITY_ENABLED'] == 'true' &&
      Assistant::AccessPolicy.context_valid?(context, ENV['ASSISTANT_SHOP_ID']) && %w[signup signin].include?(action)
    email = credentials.fetch('email', '').to_s.strip.downcase
    password = credentials.fetch('password', '').to_s
    raise ArgumentError unless email.bytesize <= 320 && password.bytesize <= 256 &&
      (credentials.keys - %w[email password first_name last_name]).empty?
    ticket = SecureRandom.urlsafe_base64(32)
    code = SecureRandom.random_number(1_000_000).to_s.rjust(6, '0')
    email_digest = Digest::SHA256.hexdigest(email)
    user = nil
    # Serialize by email across processes, including new accounts. No enumeration response.
    transaction do
      connection.execute("SELECT pg_advisory_xact_lock(#{Digest::SHA256.hexdigest(email)[0, 15].to_i(16)})")
      recent = where(shop_id: context['shop'], email_digest: email_digest).where('created_at > ?', 10.minutes.ago).count
      raise AssistantDelegation::Denied if recent >= 5
      candidate = User.find_by(email: email)
      if action == 'signup' && candidate.nil? && email.match?(URI::MailTo::EMAIL_REGEXP)
        candidate = User.new(email: email, password: password, password_confirmation: password,
          first_name: credentials['first_name'].to_s.first(100), last_name: credentials['last_name'].to_s.first(100),
          role: Role.find_by!(name: 'CUSTOMER'))
        if candidate.save
          WelcomeEmailJob.perform_later(candidate.id)
          user = candidate
        end
      elsif action == 'signin' && candidate
        valid_password = candidate.valid_password?(password)
        user = candidate if valid_password && !candidate.blocked? && !candidate.otp_enabled? && candidate.role&.name == 'CUSTOMER'
      else
        # Bound password work even when the account is missing or signup is duplicated.
        Devise::Encryptor.digest(User, password)
      end
      user = nil if user && (user.blocked? || user.role&.name != 'CUSTOMER')
      create!(shop_id: context['shop'], user: user, email_digest: email_digest,
        ticket_digest: Digest::SHA256.hexdigest(ticket), code_digest: Digest::SHA256.hexdigest(ticket + code),
        auth_fingerprint: user && fingerprint(user), context: context, expires_at: 10.minutes.from_now)
      # All outcomes have the same public ticket/response. No welcome-email verification shortcut.
      AssistantVerificationMailer.code(user, code).deliver_later if user
    end
    ticket
  end

  def self.verify!(ticket:, code:, context:)
    exchange = nil
    # Commit failed attempts before raising; retries cannot reset the limit.
    transaction do
      row = lock.find_by(ticket_digest: Digest::SHA256.hexdigest(ticket.to_s))
      if row && row.context == context && row.shop_id == ENV['ASSISTANT_SHOP_ID'] &&
          row.consumed_at.nil? && row.expires_at > Time.current && row.attempts < 5
        row.update!(attempts: row.attempts + 1)
        user = row.user&.reload
        if code.to_s.match?(/\A[0-9]{6}\z/) && user && !user.blocked? && user.role&.name == 'CUSTOMER' &&
            fingerprint(user) == row.auth_fingerprint && ActiveSupport::SecurityUtils.secure_compare(
              row.code_digest, Digest::SHA256.hexdigest(ticket.to_s + code.to_s))
          user.update!(assistant_email_verified_at: Time.current)
          exchange = AssistantDelegation.issue!(user: user, context: context, consent: true, policy_version: 'account-link-v1')
          row.update!(consumed_at: Time.current)
        end
      end
    end
    raise AssistantDelegation::Denied unless exchange
    exchange
  end
end
