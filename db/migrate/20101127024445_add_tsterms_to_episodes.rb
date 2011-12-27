class AddTstermsToEpisodes < ActiveRecord::Migration
  def self.up
    execute <<-SQL.strip
      alter table episodes add column tsterms tsvector;
      create index episodes_tsterms_idx on episodes USING gin(tsterms);
      
      create function episodes_tsterms_trigger_function() returns trigger as $$
      begin
        new.tsterms :=
         setweight(to_tsvector('pg_catalog.english', coalesce(new.name, '')), 'A') ||
         setweight(to_tsvector('pg_catalog.english', coalesce(new.description, '')), 'B');
        return new;
      end;
      $$ language 'plpgsql';
      
      create trigger episodes_tsterms_trigger
      before insert or update
      of name, description, tsterms
      on episodes for each row
      execute procedure episodes_tsterms_trigger_function();
      
      update episodes set tsterms = null;
    SQL
  end

  def self.down
    execute <<-SQL.strip
      drop trigger if exists episodes_tsterms_trigger on episodes;
      drop function if exists episodes_tsterms_trigger_function();
      alter table episodes drop column tsterms;
    SQL
  end
end
