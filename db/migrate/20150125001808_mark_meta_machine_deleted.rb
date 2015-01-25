class MarkMetaMachineDeleted < ActiveRecord::Migration
  def change
    add_column :meta_machines, :deleted, :boolean, default: false
    add_index :meta_machines, :deleted, unique: false
  end
end
