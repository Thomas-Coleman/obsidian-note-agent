class AddTemplateIdToCaptures < ActiveRecord::Migration[8.1]
  def change
    add_reference :captures, :template, null: true, foreign_key: true
  end
end
