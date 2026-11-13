# Email addresses and verification codes must never appear in job argument logs.
class AssistantVerificationDeliveryJob < ActionMailer::MailDeliveryJob
  self.log_arguments = false
  around_perform do |_job, block|
    # ActionMailer debug output includes message bodies; silence this dedicated job.
    Rails.logger.silence { block.call }
  end
end
