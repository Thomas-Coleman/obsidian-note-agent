class AddGeneratedPrefixToCaptures < ActiveRecord::Migration[8.1]
  def change
    # Add new generated_title column
    add_column :captures, :generated_title, :string

    # Rename existing columns to use generated_ prefix
    rename_column :captures, :summary, :generated_summary
    rename_column :captures, :key_points, :generated_key_points
    rename_column :captures, :markdown_content, :generated_content

    # Rename obsidian_path to obsidian_file_path for consistency
    rename_column :captures, :obsidian_path, :obsidian_file_path
  end
end
