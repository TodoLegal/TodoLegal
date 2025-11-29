class AddFullTextIndexToArticles < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE INDEX index_articles_on_body_gin 
      ON articles 
      USING gin(to_tsvector('tl_config', body));
    SQL
  end

  def down
    remove_index :articles, name: 'index_articles_on_body_gin'
  end
end
