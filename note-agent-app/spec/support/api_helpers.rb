module ApiHelpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers(user)
    {
      'Authorization' => "Bearer #{user.api_token}",
      'Content-Type' => 'application/json'
    }
  end
end
