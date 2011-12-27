class AddTstermsToFranchises < ActiveRecord::Migration
  def self.up
    execute <<-SQL.strip
      alter table franchises add column tsterms tsvector;
      create index franchises_tsterms_idx on franchises USING gin(tsterms);
      
      create function franchises_tsterms_trigger_function() returns trigger as $$
      begin
        new.tsterms :=
         setweight(to_tsvector('pg_catalog.english', coalesce(new.name, '')), 'A') ||
         setweight(to_tsvector('pg_catalog.english', coalesce(new.description, '')), 'B');
        return new;
      end;
      $$ language 'plpgsql';
      
      create trigger franchises_tsterms_trigger
      before insert or update
      of name, description, tsterms
      on franchises for each row
      execute procedure franchises_tsterms_trigger_function();
      
      update franchises set tsterms = null;
    SQL
  end

  def self.down
    execute <<-SQL.strip
      drop trigger if exists franchises_tsterms_trigger on franchises;
      drop function if exists franchises_tsterms_trigger_function();
      alter table franchises drop column tsterms;
    SQL
  end
end
