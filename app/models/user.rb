require "rotp"

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, :jwt_authenticatable,
         omniauth_providers: [ :google_oauth2 ],
         jwt_revocation_strategy: JwtDenylist

  # Associations
  belongs_to :role, optional: true
  has_many :user_permissions, dependent: :destroy
  has_many :permissions, through: :user_permissions
  has_many :assistant_delegations, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :transactions, dependent: :nullify
  has_many :reviews, dependent: :destroy
  has_many :customer_addresses, dependent: :destroy
  has_one :bonus, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges
  has_many :cart_items, dependent: :destroy
  has_many :cart_products, through: :cart_items, source: :product
  has_many :wishlist_items, dependent: :destroy
  has_many :wishlist_products, through: :wishlist_items, source: :product
  has_many :support_requests, dependent: :nullify
  has_one :affiliate_profile, dependent: :destroy
  has_many :affiliate_clicks, foreign_key: :affiliate_user_id, dependent: :destroy
  has_many :affiliate_attributions, foreign_key: :affiliate_user_id, dependent: :destroy
  has_many :affiliate_earnings, foreign_key: :affiliate_user_id, dependent: :destroy
  has_many :affiliate_withdrawals, foreign_key: :affiliate_user_id, dependent: :destroy
  has_many :affiliate_signup_referrals, foreign_key: :affiliate_user_id, dependent: :destroy
  has_many :referred_affiliate_clicks, class_name: "AffiliateClick", foreign_key: :buyer_user_id, dependent: :nullify
  has_many :referred_affiliate_attributions, class_name: "AffiliateAttribution", foreign_key: :buyer_user_id, dependent: :nullify
  has_many :referred_affiliate_earnings, class_name: "AffiliateEarning", foreign_key: :buyer_user_id, dependent: :nullify
  has_one :referred_affiliate_signup_referral, class_name: "AffiliateSignupReferral", foreign_key: :referred_user_id, dependent: :nullify

  # Validations
  validate :user_not_blocked, on: :create
  validate :phone_numbers_limit
  validate :phone_numbers_are_unique

  # Callbacks
  before_create :set_default_role
  after_update :revoke_assistant_delegations, if: :assistant_identity_changed?
  after_create :ensure_bonus
  after_destroy_commit :delete_avatar_from_r2
  after_update_commit :delete_old_avatar_from_r2, if: :saved_change_to_avatar_storage_key?

  # Override Devise's password reset email to use our custom mailer via background job
  def send_reset_password_instructions(opts = {})
    token = set_reset_password_token
    if token && persisted?
      PasswordResetEmailJob.perform_later(id, token)
    end
    token
  end

  OTP_INTERVAL = 300

  # OTP Methods
  def enable_otp!
    self.otp_secret = ROTP::Base32.random
    self.otp_enabled = true
    save!
  end

  def disable_otp!
    self.otp_enabled = false
    self.otp_secret = nil
    self.otp_verified_at = nil
    save!
  end

  def generate_otp
    return nil unless otp_enabled && otp_secret.present?
    totp = ROTP::TOTP.new(otp_secret, interval: OTP_INTERVAL)
    totp.now
  end

  def verify_otp(otp_code)
    return false unless otp_enabled && otp_secret.present?
    totp = ROTP::TOTP.new(otp_secret, interval: OTP_INTERVAL)
    result = totp.verify(otp_code, drift_behind: 1, drift_ahead: 1)
    if result
      self.otp_verified_at = Time.current
      save!
    end
    result
  end

  def has_permission?(permission_name)
    permissions.exists?(name: permission_name)
  end

  def has_role?(role_name)
    role&.name == role_name.to_s
  end

  def affiliate?
    has_role?("AFFILIATE")
  end

  def suspended_affiliate?
    affiliate_profile&.status == "suspended"
  end

  def active_affiliate?
    affiliate? && !suspended_affiliate? && !blocked?
  end

  def ensure_bonus
    bonus || create_bonus!(balance: 0)
  end

  def self.from_google_omniauth(auth)
    email = auth.info.email.to_s.downcase
    raise ArgumentError, "Google account did not return an email address" if email.blank?

    customer_role = Role.find_by(name: "CUSTOMER")
    raise ArgumentError, "Customer role is not configured" unless customer_role

    user = find_by(provider: auth.provider, uid: auth.uid) || find_by(email: email)
    if user&.role&.name.present? && !%w[CUSTOMER AFFILIATE].include?(user.role.name)
      raise ArgumentError, "Staff and admin accounts must sign in with email and password"
    end

    user ||= new(email: email, password: Devise.friendly_token[0, 32])
    user.role ||= customer_role

    user.assign_attributes(
      provider: auth.provider,
      uid: auth.uid,
      first_name: user.first_name.presence || auth.info.first_name,
      last_name: user.last_name.presence || auth.info.last_name,
      avatar: user.avatar.presence || auth.info.image
    )

    user.save!
    user
  end

  private

  def assistant_identity_changed?
    saved_change_to_email? || saved_change_to_encrypted_password? || saved_change_to_role_id? ||
      saved_change_to_blocked? || saved_change_to_assistant_email_verified_at?
  end

  def revoke_assistant_delegations
    assistant_delegations.where(revoked_at: nil).update_all(revoked_at: Time.current)
    # An email change always needs fresh ownership verification.
    update_column(:assistant_email_verified_at, nil) if saved_change_to_email?
  end

  def phone_numbers_limit
    phones = Array(phone_numbers).reject(&:blank?)
    errors.add(:phone_numbers, "cannot have more than 3 numbers") if phones.size > 3
  end

  def phone_numbers_are_unique
    phones = Array(phone_numbers).map { |phone| phone.to_s.gsub(/\s+/, "") }.reject(&:blank?)
    errors.add(:phone_numbers, "cannot contain duplicates") if phones.uniq.size != phones.size
  end

  def set_default_role
    self.role ||= Role.find_by!(name: "CUSTOMER")
  end

  def user_not_blocked
    if blocked?
      errors.add(:base, "User account is blocked")
    end
  end

  def delete_avatar_from_r2
    R2Storage.delete!(avatar_storage_key)
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.warn "R2 delete failed for user #{id}: #{e.message}"
  end

  def delete_old_avatar_from_r2
    old_key, new_key = saved_change_to_avatar_storage_key
    return if old_key.blank? || old_key == new_key

    R2Storage.delete!(old_key)
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.warn "R2 old avatar delete failed for user #{id}: #{e.message}"
  end
end
