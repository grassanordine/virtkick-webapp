class RefactorIpsAndIpRanges < ActiveRecord::Migration
  def change
    remove_column :ips, :vm_uuid, :string
    remove_column :ips, :taken, :boolean

    add_column :ips, :meta_machine_id, :integer
    add_foreign_key :ips, :meta_machines

    drop_table :ip_ranges

    create_table :ip_pools do |t|
      t.string :network
      t.string :gateway
      t.string :note
      t.index :network
    end



    #rename_table :ip_ranges, :ip_pools

    #add_column :ip_ranges, :note, :string

    create_table :hypervisors_ip_pools do |t|
      t.references :hypervisor, foreign_key: true
      t.references :ip_pool, foreign_key: true
      t.index :hypervisor_id
      t.index :ip_pool_id
    end
    rename_column :ips, :ip_range_id, :ip_pool_id

    add_index :ips, :ip, unique: true
    add_index :ips, :ip_pool_id
    add_index :ips, :meta_machine_id
  end
end
