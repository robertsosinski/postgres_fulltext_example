class CreateEpisodes < ActiveRecord::Migration
  def self.up
    create_table :episodes do |t|
      t.belongs_to :franchise
      t.string :name
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :episodes
  end
end
