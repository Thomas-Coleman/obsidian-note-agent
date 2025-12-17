class ProcessCaptureJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(capture_id)
    capture = Capture.find(capture_id)

    # Update status to processing
    capture.update!(status: :processing)

    # Process the capture
    result = CaptureProcessor.new(capture).process

    # Update capture with results
    capture.update!(
      status: :published,
      generated_title: result[:title],
      generated_summary: result[:summary],
      generated_key_points: result[:key_points]&.join("\n"),
      generated_content: result[:content],
      obsidian_file_path: result[:file_path],
      published_at: Time.current
    )
  rescue StandardError => e
    capture&.update!(
      status: :failed,
      error_message: e.message
    )
    raise
  end
end
