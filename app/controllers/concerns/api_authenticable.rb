module ApiAuthenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    
    attr_reader :current_user
  end

  private

  def authenticate_user!
    token = extract_token_from_header
    
    unless token
      render_unauthorized('Missing authentication token')
      return
    end

    @current_user = User.find_by(api_token: token)
    
    unless @current_user
      render_unauthorized('Invalid authentication token')
    end
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header

    # Expected format: "Bearer TOKEN"
    auth_header.split(' ').last if auth_header.start_with?('Bearer ')
  end

  def render_unauthorized(message = 'Unauthorized')
    render json: { error: message }, status: :unauthorized
  end
end