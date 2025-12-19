class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :api_token, null: false
      t.string :obsidian_vault_path, default: "/Users/tomcoleman/Documents/Obsidian/Tom's Obsidian Notes"

      t.timestamps

      t.index :email, unique: true
      t.index :api_token, unique: true
    end
  end
end
