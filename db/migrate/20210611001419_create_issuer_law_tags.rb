class CreateIssuerLawTags < ActiveRecord::Migration[6.1]
  def change
    create_table :issuer_law_tags do |t|
      t.integer :law_id
      t.integer :tag_id

      t.timestamps
    end
    add_index :issuer_law_tags, [:law_id, :tag_id], unique: true
  end
end
