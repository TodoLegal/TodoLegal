class AddRevisionDateToLaws < ActiveRecord::Migration[7.1]
  def change
    add_column :laws, :revision_date, :date
  end
end
