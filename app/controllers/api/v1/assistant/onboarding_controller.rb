module Api
  module V1
    module Assistant
      class OnboardingController < DelegationsController
        def authenticate
          credentials = params.require(:credentials)
          raise ArgumentError unless credentials.respond_to?(:keys) && (credentials.keys - %w[email password first_name last_name]).empty?
          ticket = ::AssistantChallenge.authenticate!(action: params.require(:intent),
            credentials: credentials.permit(:email, :password, :first_name, :last_name).to_h, context: trusted_context)
          render json: { ticket: ticket, status: 'verification_required' }
        end

        def verify
          code = ::AssistantChallenge.verify!(ticket: params.require(:ticket), code: params.require(:code), context: trusted_context)
          render json: { code: code }
        end
      end
    end
  end
end
