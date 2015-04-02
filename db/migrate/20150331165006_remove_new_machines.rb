class RemoveNewMachines < ActiveRecord::Migration
  def change
    add_column :meta_machines, :plan_id, :integer
    add_column :meta_machines, :create_params, :string # iso_distro_id, iso_image_id
    add_column :meta_machines, :finished, :boolean

    add_index :meta_machines, :finished
    remove_index :meta_machines, column: :hostname
    add_index :meta_machines, :hostname

    drop_table :new_machines, {}
  end
end
