class AssistantVerificationMailer < ApplicationMailer
  self.delivery_job = AssistantVerificationDeliveryJob

  def code(user, code)
    mail(to: user.email, subject: 'Verify your shop account link',
      body: "Your account-link verification code is #{code}. It expires in 10 minutes. Enter it only on the secure account page you opened from your shop chat. Do not send it in chat. If you did not request this, ignore this email.")
  end
end
