class RemoveContentTypeDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :captures, :content_type, from: "conversation", to: nil
  end
end
