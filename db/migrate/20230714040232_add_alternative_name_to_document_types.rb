class AddAlternativeNameToDocumentTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :document_types, :alternative_name, :string, default: ""
  end
end
