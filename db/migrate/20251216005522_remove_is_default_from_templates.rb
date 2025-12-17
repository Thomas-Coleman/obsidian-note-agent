class RemoveIsDefaultFromTemplates < ActiveRecord::Migration[8.1]
  def change
    remove_column :templates, :is_default, :boolean, default: false
  end
end
