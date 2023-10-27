class InstallPgUnaccentExtension < ActiveRecord::Migration[6.0]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS unaccent;"
  end

  def down
    execute "DROP EXTENSION IF EXISTS unaccent;"
  end
end
