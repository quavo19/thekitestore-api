require "digest"

module Api
  module V1
    module Customer
      module Products
        class ProductsController < BaseController
          REVIEW_HASH_SALT = "thekitestore-user-frontend-reviewer".freeze

          def index
            @products = Product.includes(
              :category,
              :categories,
              :images,
              :reviews,
              { sub_categories: :category },
              variant_types: { variant_options: :images }
            ).where(active: true)

            if params[:search].present?
              @products = @products.matching_search(params[:search])
            end

            if params[:category].present?
              @products = @products.left_joins(:product_categories).where(
                "products.category_id = :category_id OR product_categories.category_id = :category_id",
                category_id: params[:category]
              ).distinct
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

            if params[:price].present? && %w[asc desc].include?(params[:price].downcase)
              direction = params[:price].downcase == "asc" ? "ASC" : "DESC"
              @products = @products
                .joins("LEFT JOIN variant_types ON variant_types.product_id = products.id AND variant_types.pricing_role = 'base'")
                .joins("LEFT JOIN variant_options ON variant_options.variant_type_id = variant_types.id")
                .group("products.id")
                .order("COALESCE(MIN(variant_options.price), 0) #{direction}")
            else
              @products = @products.order(created_at: :desc)
            end

            page = params[:page] || 1
            per_page = params[:per_page] || 25
            @products = @products.page(page).per(per_page)

            render json: {
              data: @products.map do |product|
                first_image = product.images.order(created_at: :desc).first
                {
                  id: product.id,
                  type: "product",
                  attributes: {
                    name: product.name,
                    description: product.description,
                    bookable_type: product.bookable_type,
                    status: product.status,
                    base_price: product.base_price.to_f,
                    bonus_points: product.bonus_points,
                    affiliate_commission_amount: product.affiliate_commission_amount.to_f,
                    default_variant_stock: default_variant_stock_json(product),
                    review_summary: review_summary(product),
                    delivery_rate_per_km: product.delivery_rate_per_km.to_f,
                    image_url: first_image&.url,
                    category: primary_category(product),
                    categories: product.categories.sort_by(&:name).map { |category| category_json(category) },
                    sub_categories: product.sub_categories.sort_by(&:name).map { |sub_category| sub_category_json(sub_category) },
                    created_at: product.created_at.iso8601,
                    updated_at: product.updated_at.iso8601
                  }
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
            @product = Product.includes(
              :category,
              :categories,
              :images,
              :product_meta,
              { reviews: :user },
              :variant_stocks,
              { sub_categories: :category },
              variant_types: { variant_options: :images }
            ).where(active: true).find(params[:id])

            render json: {
              data: {
                id: @product.id,
                type: "product",
                attributes: {
                  name: @product.name,
                  description: @product.description,
                  bookable_type: @product.bookable_type,
                  status: @product.status,
                  base_price: @product.base_price.to_f,
                  bonus_points: @product.bonus_points,
                  affiliate_commission_amount: @product.affiliate_commission_amount.to_f,
                  default_variant_stock: default_variant_stock_json(@product),
                  variant_stocks: variant_stocks_json(@product),
                  delivery_rate_per_km: @product.delivery_rate_per_km.to_f,
                  category: primary_category(@product),
                  categories: @product.categories.sort_by(&:name).map { |category| category_json(category) },
                  sub_categories: @product.sub_categories.sort_by(&:name).map { |sub_category| sub_category_json(sub_category) },
                  images: format_product_images(@product),
                  meta: format_product_meta(@product),
                  reviews: reviews_json(@product),
                  review_summary: review_summary(@product),
                  created_at: @product.created_at.iso8601,
                  updated_at: @product.updated_at.iso8601
                }
              }
            }, status: :ok
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Product not found" }, status: :not_found
          end

          private

          def format_product_images(product)
            product.images.order(created_at: :desc).map do |image|
              {
                id: image.id,
                url: image.url,
                storage_key: image.storage_key,
                owner_type: "Product",
                owner_id: product.id,
                created_at: image.created_at.iso8601,
                updated_at: image.updated_at.iso8601
              }
            end
          end

          def variant_stocks_json(product)
            product.variant_stocks.includes(:warehouse).order(created_at: :asc).map do |stock|
              variant_stock_json(stock)
            end
          end

          def variant_stock_json(stock)
            return nil unless stock

            options = stock.variant_options.includes(:variant_type, :images)
            image = variant_option_image(options)

            {
              id: stock.id,
              warehouse_id: stock.warehouse_id,
              warehouse_name: stock.warehouse&.name,
              available_quantity: stock.processed_available_quantity,
              price: stock.price.to_f,
              option_ids: stock.option_ids,
              option_names: options.map { |option| "#{option.variant_type.name}: #{option.name}" },
              options: options.map do |option|
                {
                  id: option.id,
                  name: option.name,
                  variant_type_id: option.variant_type_id,
                  variant_type_name: option.variant_type.name,
                  variant_type_pricing_role: option.variant_type.pricing_role,
                  price: option.price.to_f,
                  images: option.images.order(created_at: :desc).map { |img| { id: img.id, url: img.url, storage_key: img.storage_key } }
                }
              end,
              image: image
            }
          end

          def variant_option_image(options)
            option = options.find { |variant_option| variant_option.images.any? }
            image = option&.images&.order(created_at: :desc)&.first
            return nil unless image

            { id: image.id, url: image.url }
          end

          def format_product_meta(product)
            product.product_meta.order(:name).map do |meta|
              {
                id: meta.id,
                name: meta.name,
                value: meta.value,
                created_at: meta.created_at.iso8601,
                updated_at: meta.updated_at.iso8601
              }
            end
          end

          def default_variant_stock_json(product)
            stock = product.variant_stocks
              .includes(:warehouse)
              .sort_by { |variant_stock| [ variant_stock.processed_available_quantity <= 0 ? 1 : 0, variant_stock.created_at ] }
              .first

            variant_stock_json(stock)
          end

          def reviews_json(product)
            product.reviews.sort_by(&:created_at).reverse.map do |review|
              {
                id: review.id,
                type: "review",
                attributes: {
                  product_id: review.product_id,
                  points: review.points,
                  comment: review.comment,
                  user: anonymous_review_user(review.user),
                  created_at: review.created_at.iso8601,
                  updated_at: review.updated_at.iso8601
                }
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

          def anonymous_review_user(user)
            digest = Digest::SHA256.hexdigest("#{REVIEW_HASH_SALT}:#{user.id}")
            code = digest.first(8).upcase

            {
              id_hash: digest,
              display_name: "Customer #{code}"
            }
          end

          def primary_category(product)
            category = product.category || product.categories.sort_by(&:name).first
            return nil unless category

            category_json(category)
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
        end
      end
    end
  end
end
