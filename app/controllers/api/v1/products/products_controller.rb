module Api
  module V1
    module Products
      class ProductsController < BaseController
        before_action :authenticate_user!
        before_action :set_product, only: [ :show, :update, :destroy ]

        def index
          authorize Product
          @products = policy_scope(Product).includes(
            :category,
            :categories,
            :images,
            :cart_items,
            :wishlist_items,
            { sub_categories: :category },
            variant_types: { variant_options: :images }
          ).order(created_at: :desc)

          if params[:search].present?
            @products = @products.matching_search(params[:search])
          end

          if params[:category_id].present?
            @products = @products.left_joins(:product_categories).where(
              "products.category_id = :category_id OR product_categories.category_id = :category_id",
              category_id: params[:category_id]
            ).distinct
          end

          if params[:sub_category_id].present?
            @products = @products.joins(:product_sub_categories).where(
              product_sub_categories: { sub_category_id: params[:sub_category_id] }
            ).distinct
          end

          if params[:active].present?
            active_value = ActiveModel::Type::Boolean.new.cast(params[:active])
            @products = @products.where(active: active_value)
          end
          @products = @products.where(bookable_type: params[:bookable_type]) if params[:bookable_type].present?

          page = params[:page] || 1
          per_page = params[:per_page] || 25
          @products = @products.page(page).per(per_page)

          render json: {
            data: @products.map do |product|
              {
                id: product.id,
                type: "product",
                attributes: product_attributes(product).merge(total_stock: calculate_total_stock(product))
              }
            end,
            meta: {
              current_page: @products.current_page,
              per_page: @products.limit_value,
              total_pages: @products.total_pages,
              total_count: @products.total_count
            }
          }, status: :ok
        end

        def show
          authorize @product
          @product = Product.includes(
            :category,
            :categories,
            :images,
            :cart_items,
            :wishlist_items,
            { reviews: :user },
            { sub_categories: :category },
            { variant_types: { variant_options: :images } }
          ).find(@product.id)

          render json: {
            data: {
              id: @product.id,
              type: "product",
              attributes: product_attributes(@product).merge(
                reviews: format_reviews(@product),
                review_summary: review_summary(@product)
              )
            }
          }, status: :ok
        end

        def create
          authorize Product

          @product = Product.new(product_params)

          if @product.save
            sync_product_taxonomy(@product)
            authorize @product
            @product.reload
            @product = Product.includes(
              :category,
              :categories,
              :images,
              :cart_items,
              :wishlist_items,
              { sub_categories: :category },
              variant_types: { variant_options: :images }
            ).find(@product.id)

            render json: {
              data: {
                id: @product.id,
                type: "product",
                  attributes: product_attributes(@product)
              }
            }, status: :created
          else
            render json: {
              error: "Validation failed",
              errors: @product.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def update
          authorize @product

          if @product.with_lock { @product.update(product_params) }
            sync_product_taxonomy(@product)
            @product.reload
            @product = Product.includes(
              :category,
              :categories,
              :images,
              :cart_items,
              :wishlist_items,
              { sub_categories: :category },
              variant_types: { variant_options: :images }
            ).find(@product.id)

            render json: {
              data: {
                id: @product.id,
                type: "product",
                  attributes: product_attributes(@product)
              }
            }, status: :ok
          else
            render json: {
              error: "Validation failed",
              errors: @product.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @product

          # Load images before destroying
          @product = Product.includes(
            :category,
            :categories,
            :images,
            :cart_items,
            :wishlist_items,
            { sub_categories: :category },
            variant_types: { variant_options: :images }
          ).find(@product.id)

          product_data = product_attributes(@product).merge(id: @product.id)

          if @product.destroy
            render json: {
              data: {
                id: product_data[:id],
                type: "product",
                attributes: product_data.except(:id)
              }
            }, status: :ok
          else
            render json: {
              error: "Failed to delete product",
              errors: @product.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def set_product
          @product = Product.find(params[:id])
        rescue ActiveRecord::RecordNotFound => e
          render json: { error: "Product not found" }, status: :not_found
          nil
        end

        def product_params
          params.require(:product).permit(
            :name,
            :description,
            :bookable_type,
            :hot_deal,
            :condition_notes,
            :compare_at_price,
            :active,
            :category_id,
            :delivery_rate_per_km,
            :bonus_points,
            :affiliate_commission_amount,
            :shipping_type,
            :weight_kg,
            :weight_class,
            :shipping_category,
            search_keywords: []
          )
        end

        def requested_category_ids
          ids = Array(params.dig(:product, :category_ids)).reject(&:blank?)
          ids << params.dig(:product, :category_id) if params.dig(:product, :category_id).present?
          ids.uniq
        end

        def requested_sub_category_ids
          Array(params.dig(:product, :sub_category_ids)).reject(&:blank?).uniq
        end

        def sync_product_taxonomy(product)
          category_ids = requested_category_ids
          sub_category_ids = requested_sub_category_ids

          product.category_ids = category_ids if params.dig(:product, :category_ids).present? || params.dig(:product, :category_id).present?
          product.sub_category_ids = sub_category_ids if params.dig(:product, :sub_category_ids).present?
          product.update_column(:category_id, category_ids.first) if category_ids.any? && product.category_id != category_ids.first
        end

        def product_attributes(product)
          categories = product.categories.sort_by(&:name)
          sub_categories = product.sub_categories.sort_by(&:name)

          {
            name: product.name,
            description: product.description,
            bookable_type: product.bookable_type,
            hot_deal: product.hot_deal,
            condition_notes: product.condition_notes,
            compare_at_price: product.compare_at_price&.to_f,
            demo: product.demo,
            active: product.active,
            status: product.status,
            bonus_points: product.bonus_points,
            affiliate_commission_amount: product.affiliate_commission_amount.to_f,
            shipping_type: product.shipping_type,
            weight_kg: product.weight_kg&.to_f,
            weight_class: product.weight_class,
            shipping_category: product.shipping_category,
            search_keywords: product.search_keywords,
            category_id: product.category_id || categories.first&.id,
            category_ids: categories.map(&:id),
            sub_category_ids: sub_categories.map(&:id),
            delivery_rate_per_km: product.delivery_rate_per_km.to_f,
            category: product.category ? {
              id: product.category.id,
              name: product.category.name
            } : categories.first && {
              id: categories.first.id,
              name: categories.first.name
            },
            categories: categories.map { |category| category_json(category) },
            sub_categories: sub_categories.map { |sub_category| sub_category_json(sub_category) },
            images: format_product_images(product),
            cart_count: product.cart_items.size,
            wishlist_count: product.wishlist_items.size,
            created_at: product.created_at.iso8601,
            updated_at: product.updated_at.iso8601
          }
        end

        def public_image_url(url)
          url&.start_with?("/demo-products/") ? "#{request.base_url}#{url}" : url
        end

        def category_json(category)
          {
            id: category.id,
            name: category.name,
            description: category.description
          }
        end

        def sub_category_json(sub_category)
          {
            id: sub_category.id,
            category_id: sub_category.category_id,
            name: sub_category.name,
            description: sub_category.description,
            category: {
              id: sub_category.category.id,
              name: sub_category.category.name
            }
          }
        end

        def calculate_total_stock(product)
          # Sum all variant stocks for this product - works for both bulk and unit products
          VariantStock.where(product_id: product.id).sum(:quantity)
        end

        def format_product_images(product)
          # Get product images
          product_images = product.images.order(created_at: :desc).map do |image|
            {
                id: image.id,
                url: public_image_url(image.url),
                storage_key: image.storage_key,
                owner_type: "Product",
              owner_id: product.id,
              created_at: image.created_at.iso8601,
              updated_at: image.updated_at.iso8601
            }
          end

          # Get variant option images
          variant_option_images = product.variant_types.flat_map do |variant_type|
            variant_type.variant_options.flat_map do |variant_option|
              variant_option.images.order(created_at: :desc).map do |image|
                {
                  id: image.id,
                  url: public_image_url(image.url),
                  storage_key: image.storage_key,
                  owner_type: "VariantOption",
                  owner_id: variant_option.id,
                  variant_option_name: variant_option.name,
                  variant_type_id: variant_type.id,
                  variant_type_name: variant_type.name,
                  created_at: image.created_at.iso8601,
                  updated_at: image.updated_at.iso8601
                }
              end
            end
          end

          # Combine all images: product images first, then variant option images
          product_images + variant_option_images
        end

        def format_reviews(product)
          product.reviews.sort_by(&:created_at).reverse.map do |review|
            {
              id: review.id,
              product_id: review.product_id,
              user_id: review.user_id,
              points: review.points,
              comment: review.comment,
              user: {
                id: review.user.id,
                email: review.user.email,
                first_name: review.user.first_name,
                last_name: review.user.last_name,
                avatar: review.user.avatar
              },
              created_at: review.created_at.iso8601,
              updated_at: review.updated_at.iso8601
            }
          end
        end

        def review_summary(product)
          reviews = product.reviews
          count = reviews.size
          average = count.positive? ? (reviews.sum(&:points).to_f / count).round(2) : 0.0

          {
            average_points: average,
            total_reviews: count
          }
        end
      end
    end
  end
end
