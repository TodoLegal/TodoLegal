class AddIssueIdToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :issue_id, :string
  end
end
