class CreateJudgementAuxiliaries < ActiveRecord::Migration[6.1]
  def change
    create_table :judgement_auxiliaries do |t|
      t.integer :document_id
      t.string :aplicable_laws

      t.timestamps
    end
  end
end
