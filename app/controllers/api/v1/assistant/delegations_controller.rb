module Api
  module V1
    module Assistant
      class DelegationsController < BaseController
        def exchange
          render json: ::AssistantDelegation.exchange!(code: params.require(:code), context: trusted_context)
        end

        def validate
          render json: ::AssistantDelegation.for_grant!(params.require(:grant), trusted_context).safe_claims
        end

        def revoke
          # Idempotent and available even after expiry/block: revocation only removes access.
          context = trusted_context
          row = ::AssistantDelegation.find_by(grant_digest: Digest::SHA256.hexdigest(params.require(:grant).to_s),
            shop_id: ENV["ASSISTANT_SHOP_ID"], context: context)
          row&.update!(revoked_at: Time.current)
          render json: { status: "revoked" }
        end

        private

        def trusted_context
          raw = params.require(:context)
          raise ::AssistantDelegation::Denied unless raw.respond_to?(:keys) && raw.keys.sort == ::Assistant::AccessPolicy::CONTEXT_KEYS.sort
          context = raw.permit(:shop, :binding, :channel, :actor, :conversation).to_h
          raise ::AssistantDelegation::Denied unless ::Assistant::AccessPolicy.context_valid?(context, ENV["ASSISTANT_SHOP_ID"])
          context
        end
      end
    end
  end
end
