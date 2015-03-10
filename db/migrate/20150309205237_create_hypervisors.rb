class CreateHypervisors < ActiveRecord::Migration
  def change
    create_table :hypervisors do |t|
      t.text :name
      t.text :host
      t.integer :port
      t.text :login
      t.text :network # json
      t.text :storages # json
      t.text :iso # json
      t.text :disk_types #json
      t.boolean :setup
      t.integer :wvm_id

      t.index :name, unique: true
      t.index :host, unique: true
      t.index :wvm_id, unique: true
    end

    add_column :meta_machines, :hypervisor_id, :integer
    remove_column :meta_machines, :libvirt_hypervisor_id, :integer
    add_index :meta_machines, :hypervisor_id
  end
end
