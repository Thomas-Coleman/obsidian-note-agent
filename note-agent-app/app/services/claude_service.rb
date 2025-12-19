class ClaudeService
  DEFAULT_SYSTEM_PROMPT = <<~PROMPT.strip
    You are an expert assistant that processes and structures text content for knowledge management.
    Your task is to analyze the provided content and extract key information in a clear, structured format.#{'  '}
    Your output should be formatted as markdown and include important links (URLs).

    Be concise, accurate, and focus on extracting the most valuable information from the content.
  PROMPT

  def initialize
    @client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
  end

  def generate(prompt:, max_tokens: 1000, system: DEFAULT_SYSTEM_PROMPT)
    Rails.logger.info "Claude Prompt: #{prompt}"
    response = @client.messages(
      parameters: {
        model: "claude-sonnet-4-20250514",
        max_tokens: max_tokens,
        system: system,
        messages: [
          {
            role: "user",
            content: prompt
          }
        ]
      }
    )
    response_text = extract_text(response)
    Rails.logger.info "Claude Response: #{response_text}"
    response_text
  rescue StandardError => e
    Rails.logger.error("Claude API Error: #{e.message}")
    raise
  end

  private

  def extract_text(response)
    response.dig("content", 0, "text") || ""
  end
end
