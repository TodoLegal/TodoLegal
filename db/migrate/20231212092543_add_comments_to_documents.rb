class AddCommentsToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :comments, :text, default: ""
  end
end
