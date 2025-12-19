class AddSkipProcessingToCaptures < ActiveRecord::Migration[8.1]
  def change
    add_column :captures, :skip_processing, :boolean, default: false, null: false
  end
end
