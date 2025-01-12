class CreateDocumentEditionHistory < ActiveRecord::Migration[7.1]
  def change
    create_table :document_edition_histories do |t|
      t.references :datapoint, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, default: ""
      t.text :comments, default: ""

      t.timestamps
    end
  end
end
