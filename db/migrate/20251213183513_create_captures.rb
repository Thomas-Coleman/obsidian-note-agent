class CreateCaptures < ActiveRecord::Migration[8.1]
  def change
    create_table :captures, charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci' do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false, limit: 16777215  # MEDIUMTEXT
      t.string :content_type, default: 'conversation'
      t.string :context
      t.json :tags
      t.integer :status, default: 0, null: false
      
      # Processing results
      t.text :summary, limit: 16777215  # MEDIUMTEXT
      t.text :key_points
      t.json :metadata
      
      # Output
      t.text :markdown_content, limit: 16777215  # MEDIUMTEXT
      t.string :obsidian_path
      t.string :obsidian_folder, default: 'Captures'
      
      t.datetime :published_at
      t.text :error_message
      
      t.timestamps
      
      t.index :status
      t.index :created_at
    end
  end
end
