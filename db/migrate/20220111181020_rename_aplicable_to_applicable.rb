class RenameAplicableToApplicable < ActiveRecord::Migration[6.1]
  def change
    rename_column :judgement_auxiliaries, :aplicable_laws, :applicable_laws
  end
end
