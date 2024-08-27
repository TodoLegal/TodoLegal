class AddFieldsToLawHyperlinks < ActiveRecord::Migration[7.1]
  def change
    add_column :law_hyperlinks, :linked_document_type, :string, default: ""
    add_column :law_hyperlinks, :linked_document_id, :integer
  end
end
