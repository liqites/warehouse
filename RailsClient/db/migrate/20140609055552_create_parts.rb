class CreateParts < ActiveRecord::Migration
  def change
    create_table(:parts, :id=>false) do |t|
      t.string :uuid, :limit => 36, :null => false
      t.string :id , :limit => 36, :primary=>true, :null=>false
      t.string :customernum
      #
      t.boolean :is_delete, :default =>false
      t.boolean :is_dirty, :default => true
      t.boolean :is_new, :default => true
      #
      t.timestamps
    end
    add_index :parts, :uuid
    add_index :parts, :id
    execute 'ALTER TABLE parts ADD PRIMARY KEY (id)'
  end
end
