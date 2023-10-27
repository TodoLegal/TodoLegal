class CreateArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :articles do |t|
      t.integer :number
      t.text :body
      t.integer :position
      t.integer :law_id

      t.timestamps
    end
  end
end
