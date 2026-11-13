module Api
  module V1
    module Auth
      class OmniauthCallbacksController < Devise::OmniauthCallbacksController
        respond_to :json

        def google_oauth2
          user = User.from_google_omniauth(request.env["omniauth.auth"])

          if user.blocked?
            redirect_to_frontend(error: "Your account has been blocked. Please contact support.")
            return
          end

          sign_in(:user, user, store: false)
          token = generate_jwt_token_for_user(user)
          response.headers["Authorization"] = "Bearer #{token}"

          redirect_to_frontend(token: token)
        rescue ActiveRecord::RecordInvalid => e
          redirect_to_frontend(error: e.record.errors.full_messages.to_sentence)
        rescue ArgumentError => e
          redirect_to_frontend(error: e.message)
        end

        def failure
          redirect_to_frontend(error: params[:message].presence || "Google authentication failed")
        end

        private

        def redirect_to_frontend(token: nil, error: nil)
          query = {}
          query[:token] = token if token.present?
          query[:error] = error if error.present?

          redirect_to "#{frontend_callback_url}?#{query.to_query}", allow_other_host: true
        end

        def frontend_callback_url
          frontend_url = affiliate_frontend_origin || requested_frontend_origin || ENV.fetch("CUSTOMER_FRONTEND_URL", ENV.fetch("FRONTEND_URL", "http://localhost:3002"))
          "#{frontend_url}/auth/google/callback"
        end

        # Select only a server-configured destination; never redirect a JWT to an
        # arbitrary origin supplied by the browser (including LAN addresses).
        def affiliate_frontend_origin
          return unless request.env.dig("omniauth.params", "frontend") == "affiliate"

          ENV["AFFILIATE_FRONTEND_URL"].presence&.delete_suffix("/") || "http://localhost:3003"
        end

        def requested_frontend_origin
          origin = request.env.dig("omniauth.params", "origin").presence
          return unless origin

          normalized_origin = origin.to_s.delete_suffix("/")
          normalized_origin if allowed_frontend_origins.include?(normalized_origin)
        end

        def allowed_frontend_origins
          @allowed_frontend_origins ||= [
            ENV["FRONTEND_URL"],
            ENV["CUSTOMER_FRONTEND_URL"],
            ENV["AFFILIATE_FRONTEND_URL"],
            ENV["CMS_FRONTEND_URL"],
            "http://localhost:3001",
            "http://localhost:3002",
            "http://localhost:3003",
            "http://localhost:5173",
            "http://localhost:5174"
          ].compact.map { |url| url.to_s.delete_suffix("/") }.uniq
        end
      end
    end
  end
end
