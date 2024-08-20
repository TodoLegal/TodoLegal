class CreateLawHyperlinks < ActiveRecord::Migration[7.1]
  def change
    create_table :law_hyperlinks do |t|
      t.integer :law_id
      t.integer :article_id
      t.text :hyperlink_text
      t.text :hyperlink
      t.string :status, default: "pendiente"

      t.timestamps
    end
  end
end
