# frozen_string_literal: true

class AddTargetDocumentIdToDatapoints < ActiveRecord::Migration[7.1]
  def change
    add_column :datapoints, :target_document_id, :integer, null: true
    add_index :datapoints, :target_document_id
    add_foreign_key :datapoints, :documents, column: :target_document_id
  end
end
