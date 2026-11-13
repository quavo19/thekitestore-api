module Api
  module V1
    module Inventory
      class VariantStocksController < BaseController
        before_action :authenticate_user!
        before_action :set_product, only: [ :index, :create ]
        before_action :set_variant_stock, only: [ :show, :update, :destroy ]

        def index
          authorize VariantStock

          if @product
            # Return variant types with options for frontend selection
            render json: cached_product_variants(@product), status: :ok
          else
            # If no product_id, return variant_stocks as before
            render json: cached_variant_stock_index, status: :ok
          end
        end

        def show
          authorize @variant_stock

          render json: {
            data: {
              id: @variant_stock.id,
              type: "variant_stock",
              attributes: {
                warehouse_id: @variant_stock.warehouse_id,
                warehouse_name: @variant_stock.warehouse&.name,
                option_ids: @variant_stock.option_ids,
                options: format_variant_options(@variant_stock),
                quantity: @variant_stock.quantity,
                available_quantity: @variant_stock.processed_available_quantity,
                in_downtime: @variant_stock.downtime_active?,
                created_at: @variant_stock.created_at.iso8601,
                updated_at: @variant_stock.updated_at.iso8601
              }
            }
          }, status: :ok
        end

        def create
          authorize VariantStock

          params_hash = variant_stock_params
          option_ids = params_hash[:option_ids] || []
          warehouse_id = params_hash[:warehouse_id]

          # Check if a variant stock with the same option_ids and warehouse_id already exists
          # Compare arrays in Ruby after loading (simpler and more reliable)
          existing_stock = VariantStock.where(warehouse_id: warehouse_id).find do |stock|
            stock.option_ids.sort == option_ids.sort
          end

          if existing_stock
            # Return existing variant stock silently
            @variant_stock = existing_stock
            authorize @variant_stock
            render json: {
              data: {
                id: @variant_stock.id,
                type: "variant_stock",
                attributes: {
                  warehouse_id: @variant_stock.warehouse_id,
                  option_ids: @variant_stock.option_ids,
                  options: format_variant_options(@variant_stock),
                  quantity: @variant_stock.quantity,
                  available_quantity: @variant_stock.processed_available_quantity,
                  in_downtime: @variant_stock.downtime_active?,
                  created_at: @variant_stock.created_at.iso8601,
                  updated_at: @variant_stock.updated_at.iso8601
                }
              }
            }, status: :ok
          else
            @variant_stock = VariantStock.new(params_hash)
            @variant_stock.product_id = @product.id if @product

            if save_stock_with_product_lock { @variant_stock.save }
              authorize @variant_stock
              render json: {
                data: {
                  id: @variant_stock.id,
                  type: "variant_stock",
                  attributes: {
                    warehouse_id: @variant_stock.warehouse_id,
                    option_ids: @variant_stock.option_ids,
                    options: format_variant_options(@variant_stock),
                    quantity: @variant_stock.quantity,
                    available_quantity: @variant_stock.processed_available_quantity,
                    in_downtime: @variant_stock.downtime_active?,
                    created_at: @variant_stock.created_at.iso8601,
                    updated_at: @variant_stock.updated_at.iso8601
                  }
                }
              }, status: :created
            else
              render json: {
                error: "Validation failed",
                errors: @variant_stock.errors.full_messages
              }, status: :unprocessable_entity
            end
          end
        end

        def update
          authorize @variant_stock

          if save_stock_with_product_lock { @variant_stock.update(variant_stock_params) }
            render json: {
              data: {
                id: @variant_stock.id,
                type: "variant_stock",
                attributes: {
                  warehouse_id: @variant_stock.warehouse_id,
                  option_ids: @variant_stock.option_ids,
                  options: format_variant_options(@variant_stock),
                  quantity: @variant_stock.quantity,
                  available_quantity: @variant_stock.processed_available_quantity,
                  in_downtime: @variant_stock.downtime_active?,
                  created_at: @variant_stock.created_at.iso8601,
                  updated_at: @variant_stock.updated_at.iso8601
                }
              }
            }, status: :ok
          else
            render json: {
              error: "Validation failed",
              errors: @variant_stock.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def destroy
          authorize @variant_stock

          options_data = format_variant_options(@variant_stock)
          option_ids_data = @variant_stock.option_ids.dup
          warehouse_id_data = @variant_stock.warehouse_id
          warehouse_name_data = @variant_stock.warehouse&.name
          quantity_data = @variant_stock.quantity
          created_at_data = @variant_stock.created_at.iso8601
          updated_at_data = @variant_stock.updated_at.iso8601

          if @variant_stock.destroy
            render json: {
              data: {
                id: @variant_stock.id,
                type: "variant_stock",
                attributes: {
                  warehouse_id: warehouse_id_data,
                  warehouse_name: warehouse_name_data,
                  option_ids: option_ids_data,
                  options: options_data,
                  quantity: quantity_data,
                  available_quantity: 0,
                  in_downtime: false,
                  created_at: created_at_data,
                  updated_at: updated_at_data
                }
              }
            }, status: :ok
          else
            render json: {
              error: "Failed to delete variant stock",
              errors: @variant_stock.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def save_stock_with_product_lock
          product = @variant_stock.product
          return yield unless product

          product.with_lock { yield }
        end

        def set_product
          @product = Product.find(params[:product_id]) if params[:product_id].present?
        rescue ActiveRecord::RecordNotFound => e
          render json: { error: "Product not found" }, status: :not_found
          nil
        end

        def set_variant_stock
          @variant_stock = VariantStock.includes(:warehouse).find(params[:id])
        rescue ActiveRecord::RecordNotFound => e
          render json: { error: "Variant stock not found" }, status: :not_found
          nil
        end

        def variant_stock_params
          params.require(:variant_stock).permit(:warehouse_id, :quantity, option_ids: [])
        end

        def cached_variant_stock_index
          Rails.cache.fetch(inventory_cache_key("variant_stocks:index"), expires_in: 1.minute) do
            variant_stocks = policy_scope(VariantStock).includes(:warehouse).order(created_at: :desc)

            {
              data: variant_stocks.map do |variant_stock|
                {
                  id: variant_stock.id,
                  type: "variant_stock",
                  attributes: {
                    warehouse_id: variant_stock.warehouse_id,
                    warehouse_name: variant_stock.warehouse&.name,
                    option_ids: variant_stock.option_ids,
                    options: format_variant_options(variant_stock),
                    quantity: variant_stock.quantity,
                    available_quantity: variant_stock.processed_available_quantity,
                    in_downtime: variant_stock.downtime_active?,
                    created_at: variant_stock.created_at.iso8601,
                    updated_at: variant_stock.updated_at.iso8601
                  }
                }
              end
            }
          end
        end

        def cached_product_variants(product)
          Rails.cache.fetch(inventory_cache_key("variant_stocks:product:#{product.id}"), expires_in: 1.minute) do
            format_product_variants(product)
          end
        end

        def inventory_cache_key(prefix)
          [
            prefix,
            "user:#{current_user.id}",
            "role:#{current_user.role_id}",
            "stocks:#{VariantStock.count}:#{cache_timestamp(VariantStock.maximum(:updated_at))}",
            "variant_types:#{VariantType.count}:#{cache_timestamp(VariantType.maximum(:updated_at))}",
            "variant_options:#{VariantOption.count}:#{cache_timestamp(VariantOption.maximum(:updated_at))}",
            "images:#{Image.count}:#{cache_timestamp(Image.maximum(:updated_at))}"
          ].join("/")
        end

        def cache_timestamp(value)
          value&.to_i || 0
        end

        def format_variant_options(variant_stock)
          return [] if variant_stock.option_ids.empty?

          variant_stock.variant_options.includes(:variant_type).map do |option|
            {
              id: option.id,
              name: option.name,
              variant_type_id: option.variant_type_id,
              variant_type_name: option.variant_type.name
            }
          end
        end

        def format_product_variants(product)
          variant_stocks = policy_scope(VariantStock)
            .where(product_id: product.id)
            .includes(:warehouse)

          # Get all variant_types for the product
          variant_types = product.variant_types.includes(:variant_options, variant_options: :images).order(:name)

          # Get all option IDs for each variant_type for quick lookup
          variant_type_option_ids = {}
          variant_types.each do |vt|
            variant_type_option_ids[vt.id] = vt.variant_options.pluck(:id)
          end

          # Build available combinations map for quick lookup
          available_combinations = variant_stocks.map do |vs|
            warehouse = vs.warehouse
            options = vs.variant_options.includes(:variant_type)
            {
              id: vs.id,
              option_ids: vs.option_ids.sort,
              options: options.slice(1, 3).map do |option|
                {
                  id: option.id,
                  name: option.name,
                  variant_type_id: option.variant_type_id,
                  variant_type_name: option.variant_type.name
                }
              end,
              quantity: vs.quantity,
              available_quantity: vs.processed_available_quantity,
              in_downtime: vs.downtime_active?,
              warehouse_id: warehouse&.id,
              warehouse_name: warehouse&.name,
              warehouse_delivery_rate_per_km: warehouse&.delivery_rate_per_km,
              warehouse_address: warehouse&.address || {},
              warehouse_location: {
                latitude: warehouse&.latitude&.to_f,
                longitude: warehouse&.longitude&.to_f
              },
              price: vs.price.to_f
            }
          end

          {
            data: variant_types.map do |variant_type|
              # Find all variant_stocks that use options from this variant_type
              option_ids_for_type = variant_type_option_ids[variant_type.id] || []
              relevant_stocks = variant_stocks.select do |vs|
                (vs.option_ids & option_ids_for_type).any?
              end

              # Calculate aggregated quantities
              total_quantity = relevant_stocks.sum(&:quantity)
              available_quantity = relevant_stocks.sum(&:processed_available_quantity)

              # Get warehouse information (use first warehouse if multiple, or aggregate)
              # For now, we'll use the first warehouse's data
              first_stock = relevant_stocks.first
              warehouse = first_stock&.warehouse

              {
                id: variant_type.id,
                type: "variant_type",
                attributes: {
                  name: variant_type.name,
                  description: variant_type.description,
                  pricing_role: variant_type.pricing_role,
                  quantity: available_quantity,
                  total_quantity: total_quantity,
                  warehouse_id: warehouse&.id,
                  warehouse_name: warehouse&.name,
                  warehouse_delivery_rate_per_km: warehouse&.delivery_rate_per_km,
                  warehouse_address: warehouse&.address || {},
                  warehouse_location: {
                    latitude: warehouse&.latitude&.to_f,
                    longitude: warehouse&.longitude&.to_f
                  },
                  warehouse_country: warehouse&.country,
                  warehouse_region: warehouse&.region,
                  warehouse_city: warehouse&.city,
                  warehouse_county: warehouse&.county,
                  options: variant_type.variant_options.order(:name).map do |option|
                    {
                      id: option.id,
                      name: option.name,
                      description: option.description,
                      price: option.price.to_f,
                      images: option.images.order(created_at: :desc).map do |image|
                        {
                          id: image.id,
                          url: image.url,
                          created_at: image.created_at.iso8601,
                          updated_at: image.updated_at.iso8601
                        }
                      end
                    }
                  end
                }
              }
            end,
            meta: {
              available_combinations: available_combinations
            }
          }
        end
      end
    end
  end
end
