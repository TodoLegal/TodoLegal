class AddColumnsToDatpoints < ActiveRecord::Migration[6.1]
  def change
    add_column :datapoints, :document_id, :integer
    add_column :datapoints, :document_tag_id, :integer
    add_column :datapoints, :status, :integer
    add_column :datapoints, :comments, :text
    add_column :datapoints, :is_active, :boolean
    add_column :datapoints, :last_verified_at, :datetime
    add_column :datapoints, :is_empty_field, :boolean
  end
end
