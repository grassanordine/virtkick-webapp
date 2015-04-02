class LibvirtImporter
  def import_all hypervisor

    admin_user = User.find_by role: 'admin'

    machines_to_import(hypervisor).each do |machine|
      user = User.find_by(email: machine.description)
      import_machine hypervisor, machine, user || admin_user
    end
  end

  def import_machine hypervisor, machine, user
    libvirt_machine_name = machine.hostname
    visible_hostname = /^(?:\d+_)(.*)$/.match(machine.hostname)[1]
    machine = MetaMachine.create_machine visible_hostname, user.id, hypervisor.id, libvirt_machine_name
    machine.save!
  rescue Exception => e
    puts "Could not import machine #{machine.hostname} from libvirt, skipping."
    ExceptionLogger.log e
  end

  private
  def machines_to_import hypervisor
    local_machines = MetaMachine.all

    remote_machines = Infra::Machine.all(hypervisor)

    local_ids = local_machines.map &:libvirt_machine_name # TODO: handle multiple hypervisors
    remote_machines.reject { |e| local_ids.include? e.hostname }
  end
end
