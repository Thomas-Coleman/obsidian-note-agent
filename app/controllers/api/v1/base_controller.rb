module Api
  module V1
    class BaseController < ActionController::API
      include ApiAuthenticable

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_content
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def render_not_found(exception)
        render json: {
          error: 'Record not found',
          message: exception.message
        }, status: :not_found
      end

      def render_unprocessable_content(exception)
        render json: {
          error: 'Validation failed',
          messages: exception.record.errors.full_messages
        }, status: :unprocessable_content
      end

      def render_bad_request(exception)
        render json: {
          error: 'Bad request',
          message: exception.message
        }, status: :bad_request
      end

      def render_error(message, status: :internal_server_error)
        render json: { error: message }, status: status
      end

      def render_success(data, status: :ok, meta: {})
        response = { data: data }
        response[:meta] = meta if meta.any?
        render json: response, status: status
      end
    end
  end
end