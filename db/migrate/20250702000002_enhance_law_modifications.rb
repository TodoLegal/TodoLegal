class EnhanceLawModifications < ActiveRecord::Migration[7.1]
  def change
    change_table :law_modifications do |t|
      t.rename :name, :modification_type
      t.references :document, foreign_key: true
      t.date :modification_date
      t.text :details, default: ""
      t.string :affected_articles
    end
    
    add_index :law_modifications, :modification_type
    add_index :law_modifications, :modification_date
    
    add_foreign_key :law_modifications, :laws
  end
end
