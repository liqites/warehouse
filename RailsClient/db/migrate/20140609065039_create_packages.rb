class CreatePackages < ActiveRecord::Migration
  def change
    create_table(:packages, :id=>false )do |t|
      t.string :uuid, :limits=>36, :null => false
      t.string :id,:limits=>36, :primary=>true, :null=>false
      t.string
      t.string :part_id
      t.integer :quantity, :default=>0
      t.datetime :in_date
      t.integer :state, :null=>false, :default=> 1
      t.string :location_id
      t.string :creator_id
      #
      t.boolean :is_delete, :default => false
      t.boolean :is_dirty, :default => true
      t.boolean :is_new, :default => true
      #
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL
        ALTER TABLE packages
ADD CONSTRAINT fk_packages_locations
FOREIGN KEY (location_id)
REFERENCES locations(id),
ADD CONSTRAINT fk_packages_parts
FOREIGN KEY (part_id)
REFERENCES parts(id),
ADD CONSTRAINT fk_packages_creators
FOREIGN KEY (creator_id)
REFERENCES users(id)
        SQL
      end

      dir.down do
        execute <<-SQL
        ALTER TABLE packages
DROP FOREIGN KEY fk_packages_locations,
DROP FOREIGN KEY fk_packages_parts,
DROP FOREIGN KEY fk_packages_creators
        SQL
      end
    end

    add_index :packages, :uuid
    add_index :packages, :id
    add_index :packages, :location_id
    add_index :packages, :part_id
    add_index :packages, :creator_id
    execute 'ALTER TABLE packages ADD PRIMARY KEY (id)'
  end
end
