class AddRevisionStatusToLaws < ActiveRecord::Migration[7.1]
  def change
    add_column :laws, :revision_status, :string, default: ""
  end
end
