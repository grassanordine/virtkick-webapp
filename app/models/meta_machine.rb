class MetaMachine < ActiveRecord::Base
  belongs_to :user
  belongs_to :hypervisor

  scope :not_deleted, -> {
    where deleted: false
  }

  after_destroy do
    force_stop rescue nil
    machine.delete
  end

  def machine
    machine = Infra::Machine.find libvirt_machine_name, hypervisor
    machine.id = self.id
    machine
  end

  def create_disk disk
    Wvm::Machine.add_disk disk, self.machine, hypervisor
  end

  def mark_deleted
    run_hook :on_mark_deleted, self.id

    update_attribute :deleted, true
  end

  def self.create_machine! hostname, user_id, hypervisor_id, libvirt_machine_name
    machine = MetaMachine.new \
        hostname: hostname,
        user_id: user_id,
        hypervisor_id: hypervisor_id,
        libvirt_machine_name: libvirt_machine_name
    machine.save!
    machine
  end

  %w(start pause resume stop force_stop restart force_restart).each do |operation|
    define_method operation do
      Wvm::Machine.send operation, hostname, hypervisor
    end
  end
end
