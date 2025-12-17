class ObsidianWriter
  def initialize(user)
    @user = user
    @vault_path = user.obsidian_vault_path
  end

  def write(content:, title:, folder: nil)
    # Sanitize filename
    filename = sanitize_filename(title)

    # Build full path
    folder_path = folder ? File.join(@vault_path, folder) : @vault_path
    FileUtils.mkdir_p(folder_path)

    file_path = File.join(folder_path, "#{filename}.md")

    # Handle duplicate filenames
    file_path = ensure_unique_filename(file_path)

    # Write the file
    File.write(file_path, content)

    # Return relative path from vault root
    file_path.sub(@vault_path + "/", "")
  end

  private

  def sanitize_filename(title)
    title
      .gsub(/[^\w\s-]/, "")
      .slice(0, 100)
  end

  def ensure_unique_filename(file_path)
    return file_path unless File.exist?(file_path)

    base = File.basename(file_path, ".md")
    dir = File.dirname(file_path)
    counter = 1

    loop do
      new_path = File.join(dir, "#{base}-#{counter}.md")
      return new_path unless File.exist?(new_path)
      counter += 1
    end
  end
end
