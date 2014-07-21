class CreateOrders < ActiveRecord::Migration
  def change
    create_table(:orders,:id=>false) do |t|
      t.string :uuid, :limit => 36, :null => false
      t.string :id, :limit => 36, :primary => type, :null => false
      t.reference :user
      t.timestamps
    end
    add_index :orders, :uuid
    add_index :orders, :id
    add_index :orders, :user_id
    execute 'ALTER TABLE orders ADD PRIMARY KEY (id)'
  end
end
