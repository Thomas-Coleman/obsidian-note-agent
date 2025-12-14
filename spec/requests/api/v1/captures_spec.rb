require 'rails_helper'

RSpec.describe 'API V1 Captures', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe 'GET /api/v1/captures' do
    let!(:captures) do
      [
        create(:capture, user: user, created_at: 3.days.ago),
        create(:capture, user: user, created_at: 2.days.ago),
        create(:capture, :published, user: user, created_at: 1.day.ago)
      ]
    end
    let!(:other_user_capture) { create(:capture, user: other_user) }

    context 'with valid authentication' do
      it 'returns all user captures' do
        get '/api/v1/captures', headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].length).to eq(3)
        expect(json_response['meta']).to include('current_page', 'total_pages', 'total_count')
      end

      it 'returns captures in reverse chronological order' do
        get '/api/v1/captures', headers: headers

        ids = json_response['data'].map { |c| c['id'] }
        expect(ids).to eq(captures.map(&:id).reverse)
      end

      it 'filters by status when provided' do
        get '/api/v1/captures', params: { status: 'published' }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].length).to eq(1)
        expect(json_response['data'].first['status']).to eq('published')
      end

      it 'paginates results' do
        get '/api/v1/captures', params: { page: 1, per_page: 2 }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].length).to eq(2)
        expect(json_response['meta']['per_page']).to eq(2)
        expect(json_response['meta']['total_count']).to eq(3)
      end

      it 'does not return other users captures' do
        get '/api/v1/captures', headers: headers

        capture_ids = json_response['data'].map { |c| c['id'] }
        expect(capture_ids).not_to include(other_user_capture.id)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/captures'

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Missing authentication token')
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized' do
        invalid_headers = { 'Authorization' => 'Bearer invalid_token' }
        get '/api/v1/captures', headers: invalid_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid authentication token')
      end
    end
  end

  describe 'GET /api/v1/captures/:id' do
    let(:capture) { create(:capture, :published, user: user) }
    let(:other_capture) { create(:capture, user: other_user) }

    context 'with valid authentication' do
      it 'returns the capture' do
        get "/api/v1/captures/#{capture.id}", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['id']).to eq(capture.id)
        expect(json_response['data']['content']).to eq(capture.content)
        expect(json_response['data']['successful?']).to eq(true)
      end

      it 'does not return other users capture' do
        get "/api/v1/captures/#{other_capture.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when capture does not exist' do
      it 'returns not found' do
        get '/api/v1/captures/99999', headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Record not found')
      end
    end
  end

  describe 'POST /api/v1/captures' do
    let(:valid_params) do
      {
        capture: {
          content: 'This is a test capture',
          content_type: 'conversation',
          context: 'Testing context',
          tags: ['test', 'api']
        }
      }
    end

    context 'with valid authentication and params' do
      it 'creates a new capture' do
        expect {
          post '/api/v1/captures', params: valid_params.to_json, headers: headers
        }.to change(Capture, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['data']['content']).to eq('This is a test capture')
        expect(json_response['data']['tags']).to eq(['test', 'api'])
      end

      it 'associates capture with current user' do
        post '/api/v1/captures', params: valid_params.to_json, headers: headers

        capture = Capture.last
        expect(capture.user_id).to eq(user.id)
      end

      it 'sets default status to pending' do
        post '/api/v1/captures', params: valid_params.to_json, headers: headers

        capture = Capture.last
        expect(capture.status).to eq('pending')
      end
    end

    context 'with invalid params' do
      it 'returns validation errors when content is missing' do
        invalid_params = { capture: { content_type: 'conversation' } }
        post '/api/v1/captures', params: invalid_params.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to include("Content can't be blank")
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        post '/api/v1/captures', params: valid_params.to_json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/captures/:id' do
    let(:capture) { create(:capture, user: user, context: 'Original context') }
    let(:update_params) do
      {
        capture: {
          context: 'Updated context',
          tags: ['updated']
        }
      }
    end

    context 'with valid authentication' do
      it 'updates the capture' do
        patch "/api/v1/captures/#{capture.id}", 
              params: update_params.to_json, 
              headers: headers

        expect(response).to have_http_status(:ok)
        capture.reload
        expect(capture.context).to eq('Updated context')
        expect(capture.tags).to eq(['updated'])
      end

      it 'does not update other users capture' do
        other_capture = create(:capture, user: other_user)
        
        patch "/api/v1/captures/#{other_capture.id}", 
              params: update_params.to_json, 
              headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid params' do
      it 'returns validation errors' do
        invalid_params = { capture: { content: '' } }
        patch "/api/v1/captures/#{capture.id}", 
              params: invalid_params.to_json, 
              headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['errors']).to include("Content can't be blank")
      end
    end
  end

  describe 'DELETE /api/v1/captures/:id' do
    let!(:capture) { create(:capture, user: user) }

    context 'with valid authentication' do
      it 'deletes the capture' do
        expect {
          delete "/api/v1/captures/#{capture.id}", headers: headers
        }.to change(Capture, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'does not delete other users capture' do
        other_capture = create(:capture, user: other_user)
        
        expect {
          delete "/api/v1/captures/#{other_capture.id}", headers: headers
        }.not_to change(Capture, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end