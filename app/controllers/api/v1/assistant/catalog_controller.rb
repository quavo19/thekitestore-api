require "uri"

module Api
  module V1
    module Assistant
      class CatalogController < BaseController
        def index
          raise ArgumentError if (params.keys - %w[controller action format query limit cursor]).any?
          query = params.fetch(:query, "").to_s
          limit = Integer(params.fetch(:limit, "5").to_s, 10)
          cursor = params[:cursor].to_s
          raise ArgumentError unless query.length <= 200 && (1..5).cover?(limit) &&
            (cursor.empty? || cursor.match?(/\A[0-9]{1,6}\z/))
          offset = cursor.empty? ? 0 : Integer(cursor, 10)
          products = Product.where(active: true)
          products = products.matching_search(query) unless query.empty?
          rows = products.order(:id).offset(offset).limit(limit + 1).to_a
          items = rows.first(limit).map { |product| ::Assistant::Catalog.product(product) }
          payload = { schema_version: "1.0", shop_id: ENV.fetch("ASSISTANT_SHOP_ID"),
            items: items, next_cursor: rows.size > limit && offset + limit <= 999_999 ? (offset + limit).to_s : nil }
          raise ArgumentError if payload.to_json.bytesize > 8192
          render json: payload
        end

        def show
          raise ArgumentError if (params.keys - %w[controller action format id]).any?
          render_catalog(item: ::Assistant::Catalog.detail(active_product))
        end

        def availability
          raise ArgumentError if (params.keys - %w[controller action format id variant_id quantity]).any?
          quantity = Integer(params.fetch(:quantity, "1").to_s, 10)
          variant_id = params[:variant_id]
          raise ArgumentError unless (1..100).cover?(quantity) &&
            (variant_id.nil? || variant_id.to_s.match?(/\A[A-Za-z0-9_-]{1,128}\z/))
          render_catalog(availability: ::Assistant::Catalog.availability(active_product, variant_id, quantity))
        end

        private

        def active_product
          raise ::AssistantDelegation::Denied unless params[:id].to_s.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
          Product.find_by(id: params[:id], active: true) || raise(::AssistantDelegation::Denied)
        end

        def render_catalog(data)
          payload = { schema_version: "1.0", shop_id: ENV.fetch("ASSISTANT_SHOP_ID") }.merge(data)
          raise ArgumentError if payload.to_json.bytesize > 8192
          render json: payload
        end

      end
    end
  end
end
