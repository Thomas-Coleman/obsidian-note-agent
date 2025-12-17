require 'rails_helper'

RSpec.describe ClaudeService do
  let(:service) { described_class.new }
  let(:anthropic_client) { instance_double(Anthropic::Client) }
  let(:api_key) { 'test_api_key_123' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ANTHROPIC_API_KEY').and_return(api_key)
    allow(Anthropic::Client).to receive(:new).and_return(anthropic_client)
  end

  describe '#initialize' do
    it 'creates an Anthropic client with the API key' do
      expect(Anthropic::Client).to receive(:new).with(access_token: api_key)
      described_class.new
    end
  end

  describe '#generate' do
    let(:prompt) { 'Test prompt content' }
    let(:max_tokens) { 1000 }
    let(:system_prompt) { ClaudeService::DEFAULT_SYSTEM_PROMPT }
    let(:claude_response) do
      {
        'content' => [
          { 'text' => 'Generated response from Claude' }
        ]
      }
    end

    before do
      allow(anthropic_client).to receive(:messages).and_return(claude_response)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    context 'with default parameters' do
      it 'generates content successfully' do
        result = service.generate(prompt: prompt)

        expect(result).to eq('Generated response from Claude')
      end

      it 'calls the Anthropic API with correct parameters' do
        service.generate(prompt: prompt)

        expect(anthropic_client).to have_received(:messages).with(
          parameters: {
            model: 'claude-sonnet-4-20250514',
            max_tokens: 1000,
            system: ClaudeService::DEFAULT_SYSTEM_PROMPT,
            messages: [
              {
                role: 'user',
                content: prompt
              }
            ]
          }
        )
      end

      it 'uses the default system prompt' do
        service.generate(prompt: prompt)

        expect(anthropic_client).to have_received(:messages).with(
          parameters: hash_including(system: ClaudeService::DEFAULT_SYSTEM_PROMPT)
        )
      end

      it 'uses default max_tokens of 1000' do
        service.generate(prompt: prompt)

        expect(anthropic_client).to have_received(:messages).with(
          parameters: hash_including(max_tokens: 1000)
        )
      end
    end

    context 'with custom parameters' do
      let(:custom_system_prompt) { 'Custom system instructions' }
      let(:custom_max_tokens) { 2000 }

      it 'uses custom system prompt' do
        service.generate(
          prompt: prompt,
          system: custom_system_prompt,
          max_tokens: custom_max_tokens
        )

        expect(anthropic_client).to have_received(:messages).with(
          parameters: hash_including(
            system: custom_system_prompt,
            max_tokens: custom_max_tokens
          )
        )
      end
    end

    context 'logging' do
      it 'logs the prompt' do
        service.generate(prompt: prompt)

        expect(Rails.logger).to have_received(:info).with("Claude Prompt: #{prompt}")
      end

      it 'logs the response' do
        service.generate(prompt: prompt)

        expect(Rails.logger).to have_received(:info).with('Claude Response: Generated response from Claude')
      end
    end

    context 'response parsing' do
      it 'extracts text from the first content block' do
        result = service.generate(prompt: prompt)

        expect(result).to eq('Generated response from Claude')
      end

      context 'when response has no content' do
        let(:claude_response) { {} }

        it 'returns empty string' do
          result = service.generate(prompt: prompt)

          expect(result).to eq('')
        end
      end

      context 'when content array is empty' do
        let(:claude_response) { { 'content' => [] } }

        it 'returns empty string' do
          result = service.generate(prompt: prompt)

          expect(result).to eq('')
        end
      end

      context 'when content has no text field' do
        let(:claude_response) { { 'content' => [{}] } }

        it 'returns empty string' do
          result = service.generate(prompt: prompt)

          expect(result).to eq('')
        end
      end
    end

    context 'error handling' do
      let(:error_message) { 'API rate limit exceeded' }

      before do
        allow(anthropic_client).to receive(:messages).and_raise(StandardError, error_message)
      end

      it 'logs the error' do
        expect {
          service.generate(prompt: prompt)
        }.to raise_error(StandardError)

        expect(Rails.logger).to have_received(:error).with("Claude API Error: #{error_message}")
      end

      it 're-raises the error' do
        expect {
          service.generate(prompt: prompt)
        }.to raise_error(StandardError, error_message)
      end
    end
  end

  describe 'DEFAULT_SYSTEM_PROMPT' do
    it 'provides instructions for knowledge management' do
      expect(ClaudeService::DEFAULT_SYSTEM_PROMPT).to include('knowledge management')
      expect(ClaudeService::DEFAULT_SYSTEM_PROMPT).to include('structured format')
      expect(ClaudeService::DEFAULT_SYSTEM_PROMPT).to include('markdown')
    end

    it 'is stripped of extra whitespace' do
      expect(ClaudeService::DEFAULT_SYSTEM_PROMPT).not_to start_with("\n")
      expect(ClaudeService::DEFAULT_SYSTEM_PROMPT).not_to end_with("\n")
    end
  end
end
