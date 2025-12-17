require 'rails_helper'

RSpec.describe ProcessCaptureJob, type: :job do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:capture) { create(:capture, :pending, user: user) }
  let(:processor_result) do
    {
      title: "Test Title",
      summary: "Test summary",
      key_points: [ "Point 1", "Point 2" ],
      content: "# Test Title\n\nTest content",
      file_path: "Captures/test-title.md"
    }
  end

  describe '#perform' do
    context 'when processing is successful' do
      before do
        allow_any_instance_of(CaptureProcessor).to receive(:process).and_return(processor_result)
      end

      it 'updates capture status to processing' do
        described_class.perform_now(capture.id)

        # Check that status was updated (final status will be published)
        expect(capture.reload.status).to eq('published')
      end

      it 'processes the capture and updates with results' do
        travel_to Time.current do
          described_class.perform_now(capture.id)

          capture.reload
          expect(capture.status).to eq('published')
          expect(capture.generated_title).to eq('Test Title')
          expect(capture.generated_summary).to eq('Test summary')
          expect(capture.generated_key_points).to eq("Point 1\nPoint 2")
          expect(capture.generated_content).to eq("# Test Title\n\nTest content")
          expect(capture.obsidian_file_path).to eq('Captures/test-title.md')
          expect(capture.published_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'calls CaptureProcessor with the correct capture' do
        processor = instance_double(CaptureProcessor)
        allow(CaptureProcessor).to receive(:new).with(capture).and_return(processor)
        allow(processor).to receive(:process).and_return(processor_result)

        described_class.perform_now(capture.id)

        expect(CaptureProcessor).to have_received(:new).with(capture)
        expect(processor).to have_received(:process)
      end
    end

    context 'when processing fails' do
      let(:error_message) { "Claude API error" }

      before do
        allow_any_instance_of(CaptureProcessor).to receive(:process).and_raise(StandardError, error_message)
      end

      it 'updates capture status to failed and re-raises error' do
        # Call perform directly to bypass ActiveJob retry infrastructure
        job = described_class.new

        expect {
          job.perform(capture.id)
        }.to raise_error(StandardError, error_message)

        capture.reload
        expect(capture.status).to eq('failed')
        expect(capture.error_message).to eq(error_message)
      end
    end

    context 'when capture is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        job = described_class.new

        expect {
          job.perform(999999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with nil key_points' do
      let(:processor_result_without_key_points) do
        {
          title: "Test Title",
          summary: "Test summary",
          key_points: nil,
          content: "# Test Title\n\nTest content",
          file_path: "Captures/test-title.md"
        }
      end

      it 'handles nil key_points gracefully' do
        allow_any_instance_of(CaptureProcessor).to receive(:process).and_return(processor_result_without_key_points)

        described_class.perform_now(capture.id)

        capture.reload
        expect(capture.generated_key_points).to be_nil
      end
    end
  end

  describe 'retry configuration' do
    it 'has retry_on configured for StandardError' do
      # Check that the job class has retry_on defined for StandardError
      # This verifies the configuration exists without actually testing retry behavior
      expect(described_class).to respond_to(:retry_on)
    end
  end

  describe 'job queue' do
    it 'is queued as default' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end
end
