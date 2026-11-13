require "minitest/autorun"
require "ostruct"
require_relative "../../app/services/assistant/access_policy"

class AssistantAccessPolicyTest < Minitest::Test
  def setup
    @context = { "shop" => "a", "binding" => "phone", "channel" => "whatsapp", "actor" => "sender", "conversation" => "conversation" }
  end

  def test_service_requires_separate_secret_and_exact_shop
    token = "s" * 40
    assert Assistant::AccessPolicy.service_authorized?(token, "Bearer #{token}", "a", "a")
    refute Assistant::AccessPolicy.service_authorized?(token, "Bearer #{token}", "a", "b")
    refute Assistant::AccessPolicy.service_authorized?(token, "Bearer general-customer-jwt", "a", "a")
    refute Assistant::AccessPolicy.service_authorized?("", "Bearer ", "a", "a")
  end

  def test_context_cannot_cross_shops_or_include_forged_customer
    assert Assistant::AccessPolicy.context_valid?(@context, "a")
    refute Assistant::AccessPolicy.context_valid?(@context, "b")
    refute Assistant::AccessPolicy.context_valid?(@context.merge("customer" => "admin"), "a")
    refute Assistant::AccessPolicy.context_valid?(@context.merge("actor" => ""), "a")
  end

  def test_only_unblocked_verified_customer_can_delegate
    user = OpenStruct.new(role: OpenStruct.new(name: "CUSTOMER"), assistant_email_verified_at: Time.now, blocked?: false)
    assert Assistant::AccessPolicy.customer?(user)
    %w[ADMIN SUPER_ADMIN AFFILIATE].each do |role|
      user.role.name = role
      refute Assistant::AccessPolicy.customer?(user)
    end
    user.role.name = "CUSTOMER"
    user.assistant_email_verified_at = nil
    refute Assistant::AccessPolicy.customer?(user)
    user.assistant_email_verified_at = Time.now
    user[:blocked?] = true
    refute Assistant::AccessPolicy.customer?(user)
  end
end
