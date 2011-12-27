class CreateSearchFunction < ActiveRecord::Migration
  def self.up
    execute <<-SQL.strip
      create or replace function search(search_query text, search_limit int default 10, search_page int default 1)
      returns table (
        id int,
        model varchar,
        search_rank real,
        headlined_name text,
        headlined_description text
      ) as $$
        declare
          search_offset int default 0;
        begin
          -- ensure that more then 100 records are not returned
          if search_limit > 100
          then search_limit := 100;
          end if;

          -- ensure that search_page is always a positive number
          if search_page < 1
          then search_page := 1;
          end if ;

          -- calculate the offset by using page and limit
          search_offset := search_limit * (search_page - 1);

          -- run the search query and return the result
          return query
          select
            sr.id as id,
            sr.model as model,
            ts_rank(sr.tsterms, tsquery) as search_rank,
            ts_headline(sr.name, tsquery) as headlined_name,
            ts_headline(sr.description, tsquery) as headlined_description
          from search_records sr, to_tsquery('pg_catalog.english', search_query) as tsquery
          where tsterms @@ tsquery
          order by search_rank desc
          limit search_limit offset search_offset;
        end;
      $$ language 'plpgsql';
    SQL
  end

  def self.down
    execute <<-SQL.strip
      drop function if exists search(text, int, int);
    SQL
  end
end
