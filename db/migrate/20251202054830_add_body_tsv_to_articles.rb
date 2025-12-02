class AddBodyTsvToArticles < ActiveRecord::Migration[7.1]
  def up
    # 1. Add tsvector column
    add_column :articles, :body_tsv, :tsvector

    # 2. Backfill existing rows
    execute <<-SQL
      UPDATE articles
      SET body_tsv = to_tsvector('tl_config', unaccent(coalesce(body, '')));
    SQL

    # 3. Create GIN index on the tsvector column
    execute <<-SQL
      CREATE INDEX index_articles_on_body_tsv_gin
      ON articles
      USING gin(body_tsv);
    SQL

    # 4. Create trigger function to keep tsvector updated
    execute <<-SQL
      CREATE OR REPLACE FUNCTION articles_body_tsv_update()
      RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        NEW.body_tsv := to_tsvector('tl_config', unaccent(coalesce(NEW.body, '')));
        RETURN NEW;
      END;
      $$;
    SQL

    # 5. Attach trigger to articles table
    execute <<-SQL
      CREATE TRIGGER articles_body_tsv_trigger
      BEFORE INSERT OR UPDATE OF body ON articles
      FOR EACH ROW EXECUTE FUNCTION articles_body_tsv_update();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS articles_body_tsv_trigger ON articles;"
    execute "DROP FUNCTION IF EXISTS articles_body_tsv_update();"
    remove_index :articles, name: :index_articles_on_body_tsv_gin if index_exists?(:articles, :index_articles_on_body_tsv_gin)
    remove_column :articles, :body_tsv if column_exists?(:articles, :body_tsv)
  end
end
