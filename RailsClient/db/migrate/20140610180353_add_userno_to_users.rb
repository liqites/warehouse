class AddUsernoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :user_no, :string, :null => false, :default => ""
    add_index :users, :user_no, :unique => true
  end
end
