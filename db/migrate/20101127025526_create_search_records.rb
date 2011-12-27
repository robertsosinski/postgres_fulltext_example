class CreateSearchRecords < ActiveRecord::Migration
  def self.up
    execute <<-SQL.strip
      create view search_records as
      select -- franchises
        id,
        cast('Franchise' as varchar) as model,
        name,
        description,
        tsterms
        from franchises
      union
      select -- episodes
        id,
        cast('Episode' as varchar) as model,
        name,
        description,
        tsterms
        from episodes;
    SQL
  end

  def self.down
    execute <<-SQL.strip
      drop view if exists search_records;
    SQL
  end
end
