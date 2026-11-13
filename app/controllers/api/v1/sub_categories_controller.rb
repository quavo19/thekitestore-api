module Api
  module V1
    class SubCategoriesController < BaseController
      before_action :authenticate_user!, except: [ :index ]
      before_action :set_sub_category, only: [ :show, :update, :destroy ]

      def index
        authorize Category

        sub_categories = SubCategory.includes(:category).order(:name)
        sub_categories = sub_categories.where(category_id: params[:category_id]) if params[:category_id].present?

        render json: { data: sub_categories.map { |sub_category| sub_category_json(sub_category) } }, status: :ok
      end

      def show
        authorize @sub_category.category, :show?

        render json: { data: sub_category_json(@sub_category) }, status: :ok
      end

      def create
        category = Category.find_by(id: sub_category_params[:category_id])
        unless category
          render json: { error: "Category not found" }, status: :not_found
          return
        end

        authorize category, :update?
        sub_category = SubCategory.new(sub_category_params)

        if sub_category.save
          render json: { data: sub_category_json(sub_category) }, status: :created
        else
          render json: { error: "Validation failed", errors: sub_category.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @sub_category.category, :update?

        if @sub_category.update(sub_category_params)
          render json: { data: sub_category_json(@sub_category.reload) }, status: :ok
        else
          render json: { error: "Validation failed", errors: @sub_category.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @sub_category.category, :destroy?

        if @sub_category.destroy
          render json: { data: sub_category_json(@sub_category) }, status: :ok
        else
          render json: { error: "Failed to delete sub category", errors: @sub_category.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_sub_category
        @sub_category = SubCategory.includes(:category).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Sub category not found" }, status: :not_found
        nil
      end

      def sub_category_params
        params.require(:sub_category).permit(:category_id, :name, :description, :image_url, :image_storage_key)
      end

      def sub_category_json(sub_category)
        {
          id: sub_category.id,
          category_id: sub_category.category_id,
          name: sub_category.name,
          description: sub_category.description,
          image_url: sub_category.image_url&.start_with?("/catalog/") ? "#{request.base_url}#{sub_category.image_url}" : sub_category.image_url,
          image_storage_key: sub_category.image_storage_key,
          category: {
            id: sub_category.category.id,
            name: sub_category.category.name
          },
          created_at: sub_category.created_at.iso8601,
          updated_at: sub_category.updated_at.iso8601
        }
      end
    end
  end
end
