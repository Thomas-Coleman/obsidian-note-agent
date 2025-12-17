require 'rails_helper'

RSpec.describe 'API V1 Templates', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe 'GET /api/v1/templates' do
    let!(:templates) do
      [
        create(:template, user: user, name: 'template1'),
        create(:template, user: user, name: 'template2')
      ]
    end
    let!(:other_user_template) { create(:template, user: other_user) }

    context 'with valid authentication' do
      it 'returns all user templates' do
        get '/api/v1/templates', headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data'].length).to eq(2)
      end

      it 'does not return other users templates' do
        get '/api/v1/templates', headers: headers

        template_ids = json_response['data'].map { |t| t['id'] }
        expect(template_ids).not_to include(other_user_template.id)
      end
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get '/api/v1/templates'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/templates/:id' do
    let(:template) { create(:template, :standard, user: user) }
    let(:other_template) { create(:template, user: other_user) }

    context 'with valid authentication' do
      it 'returns the template' do
        get "/api/v1/templates/#{template.id}", headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['id']).to eq(template.id)
        expect(json_response['data']['name']).to eq('standard')
      end

      it 'does not return other users template' do
        get "/api/v1/templates/#{other_template.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/templates' do
    let(:valid_params) do
      {
        template: {
          name: 'custom_template',
          prompt_template: 'Analyze: {{content}}',
          markdown_template: '# {{title}}\n\n{{summary}}'
        }
      }
    end

    context 'with valid authentication and params' do
      it 'creates a new template' do
        expect {
          post '/api/v1/templates', params: valid_params.to_json, headers: headers
        }.to change(Template, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['data']['name']).to eq('custom_template')
      end

      it 'associates template with current user' do
        post '/api/v1/templates', params: valid_params.to_json, headers: headers

        template = Template.last
        expect(template.user_id).to eq(user.id)
      end
    end

    context 'with invalid params' do
      it 'returns validation errors when name is missing' do
        invalid_params = { template: { prompt_template: 'test' } }
        post '/api/v1/templates', params: invalid_params.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include("Name can't be blank")
      end

      it 'returns validation errors for duplicate name' do
        create(:template, user: user, name: 'duplicate')
        duplicate_params = {
          template: {
            name: 'duplicate',
            prompt_template: 'test'
          }
        }

        post '/api/v1/templates', params: duplicate_params.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Name has already been taken')
      end
    end
  end

  describe 'PATCH /api/v1/templates/:id' do
    let(:template) { create(:template, user: user, name: 'original') }
    let(:update_params) do
      {
        template: {
          name: 'updated'
        }
      }
    end

    context 'with valid authentication' do
      it 'updates the template' do
        patch "/api/v1/templates/#{template.id}",
              params: update_params.to_json,
              headers: headers

        expect(response).to have_http_status(:ok)
        template.reload
        expect(template.name).to eq('updated')
      end

      it 'does not update other users template' do
        other_template = create(:template, user: other_user)

        patch "/api/v1/templates/#{other_template.id}",
              params: update_params.to_json,
              headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/templates/:id' do
    let!(:template) { create(:template, user: user) }

    context 'with valid authentication' do
      it 'deletes the template' do
        expect {
          delete "/api/v1/templates/#{template.id}", headers: headers
        }.to change(Template, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'does not delete other users template' do
        other_template = create(:template, user: other_user)

        expect {
          delete "/api/v1/templates/#{other_template.id}", headers: headers
        }.not_to change(Template, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
