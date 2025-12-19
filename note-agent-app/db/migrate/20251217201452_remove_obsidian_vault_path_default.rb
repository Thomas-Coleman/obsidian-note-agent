class RemoveObsidianVaultPathDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :obsidian_vault_path, from: "/Users/tomcoleman/Documents/Obsidian/Tom's Obsidian Notes", to: nil
  end
end
