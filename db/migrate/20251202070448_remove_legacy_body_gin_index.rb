class RemoveLegacyBodyGinIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = "index_articles_on_body_gin"

  def up
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
  end

  def down
    return if ActiveRecord::Base.connection.indexes(:articles).any? { |i| i.name == INDEX_NAME }
    execute <<-SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
      ON articles
      USING gin(to_tsvector('tl_config', body));
    SQL
  end
end