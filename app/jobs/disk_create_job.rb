class DiskCreateJob < TrackableJob
  self.set_max_attempts 10, 5.seconds

  def perform meta_machine_id, disk_params
    machine = MetaMachine.find(meta_machine_id)

    hypervisor_id = machine.libvirt_hypervisor_id
    disk_params[:pool] = Wvm::StoragePool.to_local(disk_params[:type], hypervisor_id)[:id]
    disk = Infra::Disk.new disk_params
    machine.create_disk disk
  end
end