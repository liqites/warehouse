class AddSupplierCloumnToPart < ActiveRecord::Migration
  def change
    add_column :parts, :supplier, :string
  end
end
