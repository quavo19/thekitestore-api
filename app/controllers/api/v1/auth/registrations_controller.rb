module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        # Prevent Devise from trying to use sessions
        def create
          build_resource(sign_up_params)
          # Public registration always creates customers; staff roles require admin assignment.
          resource.role = Role.find_by!(name: "CUSTOMER")

          resource.save
          if resource.persisted?
            sign_in(resource_name, resource, store: false)
            WelcomeEmailJob.perform_later(resource.id)
            respond_with(resource)
          else
            respond_with(resource)
          end
        end

        private

        def sign_up_params
          params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :avatar, :avatar_storage_key)
        end

        def respond_with(current_user, _opts = {})
          if resource.persisted?
            render json: {
              status: {
                code: 200,
                message: "Signed up successfully."
              },
              data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
            }, status: :ok
          else
            render json: {
              error: resource.errors.full_messages.to_sentence
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
