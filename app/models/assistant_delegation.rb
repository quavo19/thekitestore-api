require "digest"
require "securerandom"

class AssistantDelegation < ApplicationRecord
  class Denied < StandardError; end
  belongs_to :user
  AUDIENCE = "shop-assistant".freeze

  # Internal backend entry only. Phase 8C must authenticate/verify the browser and consent.
  # Never expose this as a service endpoint that accepts a customer ID or role.
  def self.issue!(user:, context:, consent:, policy_version:)
    shop = ENV.fetch("ASSISTANT_SHOP_ID", "")
    unless ENV["ASSISTANT_IDENTITY_ENABLED"] == "true" && !shop.empty? &&
        consent == true && policy_version.is_a?(String) && !policy_version.empty? &&
        Assistant::AccessPolicy.context_valid?(context, shop) && Assistant::AccessPolicy.customer?(user)
      raise Denied
    end
    issued_at = Time.current
    code = SecureRandom.urlsafe_base64(32)
    create!(user: user, shop_id: shop, audience: AUDIENCE, context: context,
      code_digest: Digest::SHA256.hexdigest(code), issued_at: issued_at,
      expires_at: issued_at + 5.minutes, consented_at: Time.current, policy_version: policy_version)
    code
  end

  def self.exchange!(code:, context:)
    grant = SecureRandom.urlsafe_base64(32)
    transaction do
      row = lock.find_by(code_digest: Digest::SHA256.hexdigest(code.to_s))
      raise Denied unless row && row.consumed_at.nil?
      row.authorize!(context)
      row.update!(consumed_at: Time.current, grant_digest: Digest::SHA256.hexdigest(grant))
      row.safe_claims.merge(grant: grant)
    end
  end

  def self.for_grant!(grant, context)
    row = find_by(grant_digest: Digest::SHA256.hexdigest(grant.to_s))
    raise Denied unless row && row.consumed_at
    row.authorize!(context)
    row
  end

  def authorize!(requested_context)
    unless ENV["ASSISTANT_IDENTITY_ENABLED"] == "true" &&
        shop_id == ENV["ASSISTANT_SHOP_ID"] && audience == AUDIENCE &&
        Assistant::AccessPolicy.context_valid?(requested_context, shop_id) && context == requested_context &&
        revoked_at.nil? && expires_at > Time.current && issued_at <= Time.current &&
        expires_at <= issued_at + 5.minutes && Assistant::AccessPolicy.customer?(user.reload)
      raise Denied
    end
  end

  def safe_claims
    { shop_id: shop_id, audience: audience, context: context, subject: user_id.to_s,
      role: "CUSTOMER", email_verified: true, active: true, scopes: ["identity.link"],
      issued_at: issued_at.to_f, expires_at: expires_at.to_f }
  end
end
