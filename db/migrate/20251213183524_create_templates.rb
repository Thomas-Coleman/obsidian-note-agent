class CreateTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :templates, charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci' do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :prompt_template, null: false, limit: 16777215  # MEDIUMTEXT
      t.text :markdown_template, limit: 16777215  # MEDIUMTEXT
      t.boolean :is_default, default: false
      
      t.timestamps
      
      t.index [:user_id, :name], unique: true
    end
  end
end