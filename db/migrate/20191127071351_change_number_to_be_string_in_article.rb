class ChangeNumberToBeStringInArticle < ActiveRecord::Migration[6.0]
  def up
    change_column :articles, :number, :string
  end

  def down
    change_column :articles, :number, :integer
  end
end
