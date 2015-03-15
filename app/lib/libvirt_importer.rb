class LibvirtImporter
  def import_all hypervisor

    admin_user = User.find_by role: 'admin'

    machines_to_import(hypervisor).each do |machine|
      user = User.find_by(email: machine.description)
      import_machine machine, user || admin_user
    end
  end

  def import_machine machine, user
    MetaMachine.create_machine! machine.hostname, user.id, machine.hypervisor_id, machine.hostname
  rescue Exception => e
    puts "Could not import machine #{machine.hostname} from libvirt, skipping."
  end

  private
  def machines_to_import hypervisor
    local_machines = MetaMachine.all

    remote_machines = Infra::Machine.all(hypervisor)

    local_ids = local_machines.map &:libvirt_machine_name # TODO: handle multiple hypervisors
    remote_machines.reject { |e| local_ids.include? e.hostname }
  end
end
