module Api
  module V1
    module Assistant
      class BaseController < ActionController::API
        before_action :authenticate_assistant!
        before_action :private_headers
        rescue_from ::AssistantDelegation::Denied, with: :denied
        rescue_from ActionController::ParameterMissing, ArgumentError, with: :invalid_request

        private

        def authenticate_assistant!
          unless ENV["ASSISTANT_API_ENABLED"] == "true" && ::Assistant::AccessPolicy.service_authorized?(
              ENV["ASSISTANT_SERVICE_TOKEN"], request.headers["Authorization"],
              ENV["ASSISTANT_SHOP_ID"], request.headers["X-Assistant-Shop"])
            denied
          end
        end

        def private_headers
          response.headers["Cache-Control"] = "no-store"
          response.headers["Referrer-Policy"] = "no-referrer"
        end

        def denied
          render json: { error: { code: "not_found" } }, status: :not_found
        end

        def invalid_request
          render json: { error: { code: "invalid_request" } }, status: :unprocessable_entity
        end
      end
    end
  end
end
