module Api
  module V1
    class CategoriesController < BaseController
      before_action :authenticate_user!, except: [ :index ]
      before_action :set_category, only: [ :show, :update, :destroy ]

      def index
        authorize Category
        @categories = policy_scope(Category)
          .left_joins(:sub_categories)
          .select("categories.*, COUNT(sub_categories.id) AS sub_categories_count")
          .group("categories.id")
          .order(:name)

        render json: {
          data: @categories.map { |category| category_json(category) }
        }, status: :ok
      end

      def show
        authorize @category

        render json: { data: category_json(@category, include_sub_categories: true) }, status: :ok
      end

      def create
        authorize Category

        @category = Category.new(category_params)

        if @category.save
          authorize @category
          render json: { data: category_json(@category.reload) }, status: :created
        else
          render json: {
            error: "Validation failed",
            errors: @category.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @category

        if @category.update(category_params)
          render json: { data: category_json(@category.reload) }, status: :ok
        else
          render json: {
            error: "Validation failed",
            errors: @category.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @category

        if @category.destroy
          render json: { data: category_json(@category) }, status: :ok
        else
          render json: {
            error: "Failed to delete category",
            errors: @category.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_category
        @category = Category.includes(:sub_categories).find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: "Category not found" }, status: :not_found
        nil
      end

      def category_params
        params.require(:category).permit(:name, :description, :image_url, :image_storage_key)
      end

      def category_json(category, include_sub_categories: false)
        payload = {
          id: category.id,
          name: category.name,
          description: category.description,
          image_url: public_image_url(category.image_url),
          image_storage_key: category.image_storage_key,
          sub_categories_count: sub_categories_count_for(category),
          created_at: category.created_at.iso8601,
          updated_at: category.updated_at.iso8601
        }

        return payload unless include_sub_categories

        payload.merge(
          sub_categories: category.sub_categories.order(:name).map do |sub_category|
            {
              id: sub_category.id,
              category_id: sub_category.category_id,
              name: sub_category.name,
              description: sub_category.description,
              image_url: public_image_url(sub_category.image_url),
              image_storage_key: sub_category.image_storage_key,
              created_at: sub_category.created_at.iso8601,
              updated_at: sub_category.updated_at.iso8601
            }
          end
        )
      end

      def public_image_url(path)
        return path unless path&.start_with?("/catalog/")

        "#{request.base_url}#{path}"
      end

      def sub_categories_count_for(category)
        return category.read_attribute(:sub_categories_count).to_i if category.has_attribute?(:sub_categories_count)

        category.sub_categories.size
      end
    end
  end
end
