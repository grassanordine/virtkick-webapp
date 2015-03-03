class LibvirtImporter
  def import_all user
    machines_to_import.each do |machine|
      import_machine machine, user # TODO: multiple hypervisors
    end
  end

  def import_machine machine, user
    MetaMachine.create_machine! machine.hostname, user.id, machine.hypervisor_id, machine.hostname
  rescue Exception => e
    puts "Could not import machine #{machine.hostname} from libvirt, skipping."
  end

  private
  def machines_to_import
    local_machines = MetaMachine.all

    remote_machines = []
    Wvm::Hypervisor.all.each do |hypervisor|
      remote_machines = remote_machines + Infra::Machine.all(hypervisor.id)
    end
    local_ids = local_machines.map &:libvirt_machine_name # TODO: handle multiple hypervisors
    remote_machines.reject { |e| local_ids.include? e.hostname }
  end
end
