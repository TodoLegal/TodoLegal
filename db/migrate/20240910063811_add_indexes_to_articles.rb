class AddIndexesToArticles < ActiveRecord::Migration[7.1]
  def change
    add_index :articles, :number
    add_index :articles, :law_id
  end
end
