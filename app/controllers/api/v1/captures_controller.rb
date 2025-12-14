module Api
  module V1
    class CapturesController < BaseController
      before_action :set_capture, only: [:show, :update, :destroy]

      # GET /api/v1/captures
      def index
        captures = current_user.captures
                              .by_status(params[:status])
                              .recent
                              .page(params[:page])
                              .per(params[:per_page] || 20)

        render_success(
          captures.as_json(only: [:id, :content_type, :context, :status, :created_at, :published_at]),
          meta: pagination_meta(captures)
        )
      end

      # GET /api/v1/captures/:id
      def show
        render_success(@capture.as_json(
          except: [:user_id],
          methods: [:successful?, :processing?]
        ))
      end

      # POST /api/v1/captures
      def create
        capture = current_user.captures.build(capture_params)

        if capture.save
          # TODO: Enqueue background job for processing
          render_success(capture.as_json(except: [:user_id]), status: :created)
        else
          render json: { errors: capture.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PATCH/PUT /api/v1/captures/:id
      def update
        if @capture.update(capture_params)
          render_success(@capture.as_json(except: [:user_id]))
        else
          render json: { errors: @capture.errors.full_messages }, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/captures/:id
      def destroy
        @capture.destroy
        head :no_content
      end

      private

      def set_capture
        @capture = current_user.captures.find(params[:id])
      end

      def capture_params
        params.require(:capture).permit(
          :content,
          :content_type,
          :context,
          :obsidian_folder,
          tags: []
        )
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
    end
  end
end