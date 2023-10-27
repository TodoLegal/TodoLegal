class AddPositionToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :position, :integer
  end
end
