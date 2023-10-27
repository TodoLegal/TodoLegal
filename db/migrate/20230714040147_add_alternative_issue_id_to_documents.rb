class AddAlternativeIssueIdToDocuments < ActiveRecord::Migration[6.1]
  def change
    add_column :documents, :alternative_issue_id, :string, default: ""
  end
end
