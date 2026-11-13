module Api
  module V1
    module Customer
      class CartItemsController < BaseController
        before_action :authenticate_user!
        before_action :set_product, only: [ :create ]
        before_action :set_variant_stock, only: [ :create ]

        def index
          cart_items = current_user.cart_items.includes(:variant_stock, product: [ :category, :images ]).order(created_at: :desc)

          render json: { data: cart_items.map { |item| item_json(item) } }, status: :ok
        end

        def create
          return if performed?

          cart_item = current_user.cart_items.find_or_initialize_by(product: @product, variant_stock: @variant_stock)
          requested_quantity = cart_quantity
          cart_item.quantity = cart_item.persisted? ? cart_item.quantity + requested_quantity : requested_quantity

          if cart_item.save
            render json: { data: item_json(cart_item) }, status: :created
          else
            render json: { error: "Validation failed", errors: cart_item.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          cart_item = current_user.cart_items.find_by(id: params[:id])
          cart_item ||= current_user.cart_items.find_by(
            product_id: params[:product_id] || params[:id],
            variant_stock_id: params[:variant_stock_id].presence
          )

          unless cart_item
            render json: { error: "Cart item not found" }, status: :not_found
            return
          end

          if cart_item.update(quantity: cart_quantity)
            render json: { data: item_json(cart_item) }, status: :ok
          else
            render json: { error: "Validation failed", errors: cart_item.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          cart_item = nil

          if params[:product_id].present?
            cart_item = current_user.cart_items.find_by(
              product_id: params[:product_id],
              variant_stock_id: params[:variant_stock_id].presence
            )
          end

          cart_item ||= current_user.cart_items.find_by(id: params[:id])
          cart_item ||= current_user.cart_items.find_by(variant_stock_id: params[:id])
          cart_item ||= current_user.cart_items.find_by(product_id: params[:id], variant_stock_id: nil)

          unless cart_item
            render json: { error: "Cart item not found" }, status: :not_found
            return
          end

          cart_item.destroy
          render json: { message: "Removed from cart" }, status: :ok
        end

        private

        def set_product
          @product = Product.where(active: true, demo: false).find_by(id: params[:product_id] || params[:id])
          return if @product

          render json: { error: "Product not found" }, status: :not_found
        end

        def set_variant_stock
          return if params[:variant_stock_id].blank?

          @variant_stock = @product.variant_stocks.find_by(id: params[:variant_stock_id])
          return if @variant_stock

          render json: { error: "Variant not found" }, status: :not_found
        end

        def cart_quantity
          quantity = params[:quantity] || params.dig(:cart_item, :quantity)
          [ quantity.to_i, 1 ].max
        end

        def item_json(item)
          product = item.product
          first_image = product.images.order(created_at: :desc).first
          stock = item.variant_stock || default_variant_stock(product)

          {
            id: item.id,
            type: "cart_item",
            attributes: {
              user_id: item.user_id,
              product_id: item.product_id,
              variant_stock_id: stock&.id,
              quantity: item.quantity,
              product: {
                id: product.id,
                name: product.name,
                description: product.description,
                active: product.active,
                base_price: (stock&.price || product.base_price).to_f,
                bonus_points: product.bonus_points,
                default_variant_stock: variant_stock_json(stock),
                selected_variant_stock: variant_stock_json(stock),
                category: product.category ? { id: product.category.id, name: product.category.name } : nil,
                image_url: variant_stock_image(stock)&.dig(:url) || first_image&.url
              },
              created_at: item.created_at.iso8601,
              updated_at: item.updated_at.iso8601
            }
          }
        end

        def default_variant_stock(product)
          product.variant_stocks
            .includes(:warehouse)
            .sort_by { |variant_stock| [ variant_stock.processed_available_quantity <= 0 ? 1 : 0, variant_stock.created_at ] }
            .first
        end

        def variant_stock_json(stock)
          return nil unless stock

          {
            id: stock.id,
            warehouse_id: stock.warehouse_id,
            warehouse_name: stock.warehouse&.name,
            available_quantity: stock.processed_available_quantity,
            price: stock.price.to_f,
            option_ids: stock.option_ids,
            option_names: stock.variant_options.includes(:variant_type).map { |option| "#{option.variant_type.name}: #{option.name}" },
            options: stock.variant_options.includes(:variant_type).map do |option|
              {
                id: option.id,
                name: option.name,
                variant_type_id: option.variant_type_id,
                variant_type_name: option.variant_type.name,
                variant_type_pricing_role: option.variant_type.pricing_role,
                price: option.price.to_f
              }
            end,
            image: variant_stock_image(stock)
          }
        end

        def variant_stock_image(stock)
          return nil unless stock

          option = stock.variant_options.find { |variant_option| variant_option.images.any? }
          image = option&.images&.order(created_at: :desc)&.first
          return nil unless image

          { id: image.id, url: image.url }
        end
      end
    end
  end
end
