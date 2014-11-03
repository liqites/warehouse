class LocationContainer < ActiveRecord::Migration
  def up
    create_table :location_containers,:id=>false do |t|
      t.string :id, :limit => 36, :primary => true, :null => false
      t.string :containerable_type
      t.string :containerable_id
      t.string :location_id
      #
      t.boolean :is_delete, :default => false
      t.boolean :is_dirty, :default => true
      t.boolean :is_new, :default => true
      #
      t.timestamps
    end
    add_index :location_containers, :id
    add_index :location_containers, :containerable_type
    add_index :location_containers, :containerable_id
    add_index :location_containers, :location_id

    execute 'ALTER TABLE location_containers ADD PRIMARY KEY (id)'
  end

  def down
    drop_table :location_containers
  end
end
