require "digest"

module Assistant
  # Kept independent of Rails so denial rules can be verified without external services.
  module AccessPolicy
    CONTEXT_KEYS = %w[shop binding channel actor conversation].freeze

    def self.context_valid?(context, shop)
      context.is_a?(Hash) && context.keys.sort == CONTEXT_KEYS.sort &&
        context.values.all? { |value| value.is_a?(String) && !value.empty? && value.length <= 128 } &&
        context["shop"] == shop && %w[web whatsapp].include?(context["channel"])
    end

    def self.customer?(user)
      !user.blocked? && user.role&.name == "CUSTOMER" && !user.assistant_email_verified_at.nil?
    end

    def self.service_authorized?(expected, authorization, expected_shop, requested_shop)
      return false if expected.to_s.bytesize < 32 || expected_shop.to_s.empty? || requested_shop != expected_shop
      return false unless authorization.to_s.start_with?("Bearer ")
      left = Digest::SHA256.digest(expected)
      right = Digest::SHA256.digest(authorization.delete_prefix("Bearer "))
      # OpenSSL fixed-length comparison, without inheriting shop/customer login tokens.
      require "openssl"
      OpenSSL.fixed_length_secure_compare(left, right)
    end
  end
end
