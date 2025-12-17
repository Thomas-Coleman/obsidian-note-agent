class CaptureProcessor
  def initialize(capture)
    @capture = capture
    @user = capture.user
  end

  def process
    # 1. Get the template
    template = find_template
    
    # 2. Generate content with Claude
    ai_response = generate_with_claude(template)
    
    # 3. Parse the AI response
    parsed_content = parse_ai_response(ai_response)

    Rails.logger.info "Parsed content - Key Points: #{parsed_content[:key_points].inspect}"
    Rails.logger.info "Parsed content - Tags: #{parsed_content[:tags].inspect}"

    # 4. Render the markdown
    markdown_content = render_markdown(template, parsed_content)

    Rails.logger.info "Generated markdown length: #{markdown_content.length}"
    Rails.logger.info "Generated markdown preview:\n#{markdown_content[0..500]}"

    # 5. Write to Obsidian vault
    file_path = write_to_obsidian(markdown_content, parsed_content[:title])
    
    {
      title: parsed_content[:title],
      summary: parsed_content[:summary],
      key_points: parsed_content[:key_points],
      content: markdown_content,
      file_path: file_path
    }
  end

  private

  def find_template
    # Use capture's assigned template or fall back to system default
    @capture.template || Template.new(Template.defaults["standard"])
  end

  def generate_with_claude(template)
    prompt = render_prompt(template.prompt_template)
    
    ClaudeService.new.generate(
      prompt: prompt,
      max_tokens: 2000
    )
  end

  def render_prompt(template_string)
    # Replace template variables
    template_string
      .gsub("{{content}}", @capture.content)
      .gsub("{{context}}", @capture.context || "")
      .gsub("{{content_type}}", @capture.content_type)
  end

  def parse_ai_response(response)
    # Extract structured data from Claude's response
    # For now, we'll use simple parsing
    # Later, we can use structured outputs or JSON mode
    
    lines = response.split("\n")
    
    {
      title: extract_title(lines),
      summary: extract_summary(lines),
      key_points: extract_key_points(lines),
      tags: extract_tags(lines) + @capture.tags
    }
  end

  def extract_title(lines)
    title_line = lines.find { |line| line.match?(/^(Title:|#)/) }
    title_line&.gsub(/^(Title:|#)\s*/, "")&.strip || "Untitled Note"
  end

  def extract_summary(lines)
    summary_start = lines.index { |line| line.match?(/^(Summary:|##\s*Summary)/) }
    return "" unless summary_start

    summary_lines = []
    (summary_start + 1...lines.length).each do |i|
      break if lines[i].match?(/^(##|Key Points:|Tags:)/)
      summary_lines << lines[i] unless lines[i].strip.empty?
    end
    
    summary_lines.join("\n")
  end

  def extract_key_points(lines)
    points_start = lines.index { |line| line.match?(/^(Key Points:|##\s*Key Points)/) }
    return [] unless points_start

    points = []
    (points_start + 1...lines.length).each do |i|
      break if lines[i].match?(/^(##|Tags:|Suggested Tags:)/)
      # Match lines starting with -, *, or • (bullet character)
      if lines[i].match?(/^[-*•]\s+/)
        points << lines[i].gsub(/^[-*•]\s+/, "").strip
      end
    end

    points
  end

  def extract_tags(lines)
    # Try to find "Tags:" or "Suggested Tags:" header
    tags_start = lines.index { |line| line.match?(/^(Tags:|##\s*(Suggested )?Tags)/) }

    Rails.logger.info "Tag extraction - tags_start: #{tags_start.inspect}"
    return [] unless tags_start

    # Check if tags are on the same line (e.g., "Tags: tag1 tag2")
    first_line = lines[tags_start]
    Rails.logger.info "Tag extraction - first_line: #{first_line.inspect}"

    if first_line.match?(/^Tags:\s*\S/)
      return first_line
        .gsub(/^Tags:\s*/, "")
        .split(/[,\s]+/)
        .map { |tag| tag.gsub(/^#/, "").gsub(/`/, "") }
        .reject(&:empty?)
    end

    # Initialize tags array
    tags = []

    # Check the next few lines for tags (might be empty line first)
    (tags_start + 1...lines.length).each do |i|
      line = lines[i]
      Rails.logger.info "Tag extraction - checking line #{i}: #{line.inspect}"

      # Stop if we hit another section
      break if line.match?(/^(##|[A-Z][a-z]+:)/)

      # Skip empty lines
      next if line.strip.empty?

      # Check for bullet point tags FIRST (e.g., "- #tag" or "- `tag`")
      if line.match?(/^[-*•]\s+/)
        tag = line.gsub(/^[-*•]\s+/, "").strip.gsub(/`/, "").gsub(/^#/, "")
        tags << tag unless tag.empty?
        next
      end

      # Check if line contains backtick-wrapped tags (inline, not bullets)
      # e.g., "`#ActiveJob` `#RubyOnRails` `#JobQueue`"
      if line.include?('`') && !line.match?(/^[-*•]/)
        tags = line
          .split(/\s+/)
          .map { |tag| tag.gsub(/`/, "").gsub(/^#/, "").strip }
          .reject(&:empty?)
        Rails.logger.info "Tag extraction - found backtick tags: #{tags.inspect}"
        return tags
      end
    end

    Rails.logger.info "Tag extraction - final result: #{tags.inspect}"
    tags
  end

  def render_markdown(template, parsed_content)
    markdown = template.markdown_template
      .gsub("{{title}}", parsed_content[:title])
      .gsub("{{summary}}", parsed_content[:summary])
      .gsub("{{key_points}}", format_key_points(parsed_content[:key_points]))
      .gsub("{{tags}}", parsed_content[:tags].map { |t| "  - #{t}" }.join("\n"))
      .gsub("{{created_at}}", @capture.created_at.strftime("%Y-%m-%d %H:%M"))
      .gsub("{{content_type}}", @capture.content_type)
    
    # Remove optional sections if empty
    markdown.gsub(/{{context_section}}/, @capture.context ? "## Context\n\n#{@capture.context}" : "")
            .gsub(/{{related_notes_section}}/, "")
  end

  def format_key_points(points)
    return "" if points.empty?
    points.map { |point| "- #{point}" }.join("\n")
  end

  def write_to_obsidian(content, title)
    ObsidianWriter.new(@user).write(
      content: content,
      title: title,
      folder: @capture.obsidian_folder
    )
  end
end