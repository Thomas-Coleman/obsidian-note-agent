module Api
  module V1
    class TemplatesController < BaseController
        before_action :set_template, only: [:show, :update, :destroy]


        # GET /api/v1/templates
      def index
        templates = current_user.templates.order(created_at: :desc)
        render_success(templates)
      end

      # GET /api/v1/templates/:id
      def show
        render_success(@template)
      end

      # POST /api/v1/templates
      def create
        template = current_user.templates.build(template_params)

        if template.save
          render_success(template, status: :created)
        else
          render json: { errors: template.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PATCH/PUT /api/v1/templates/:id
      def update
        if @template.update(template_params)
          render_success(@template)
        else
          render json: { errors: @template.errors.full_messages }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/templates/:id
      def destroy
        @template.destroy
        head :no_content
      end

      private

      def set_template
        @template = current_user.templates.find(params[:id])
      end

      def template_params
        params.require(:template).permit(
          :name,
          :prompt_template,
          :markdown_template,
          :is_default
        )
      end
    end
  end
end