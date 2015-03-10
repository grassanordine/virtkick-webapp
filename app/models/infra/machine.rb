require 'active_hash'

class Infra::Machine < Infra::Base
  attr_accessor :id
  attr_accessor :hostname, :uuid, :memory
  attr_accessor :processors, :processor_usage
  attr_accessor :status
  attr_accessor :vnc_port, :vnc_listen_ip
  attr_accessor :vnc_password
  attr_accessor :disks
  attr_accessor :networks
  attr_accessor :iso_dir, :iso_distro_id, :iso_image_id
  attr_accessor :hypervisor_id
  attr_accessor :mac_address

  def self.all hypervisor
    Wvm::Machine.all hypervisor
  end

  def self.find hostname, hypervisor
    Wvm::Machine.find hostname, hypervisor
  end

  def self.create new_machine, hypervisor
    Wvm::Machine.create new_machine, hypervisor
  end

  def id
    @id ||= MetaMachine.where(hostname: hostname).first.id
  end

  %w(start pause resume stop force_stop restart force_restart).each do |operation|
    define_method operation do ||
      Wvm::Machine.send operation, hostname, Hypervisor.find(hypervisor_id)
    end
  end

  def create_disk disk
    Wvm::Machine.add_disk disk, self, Hypervisor.find(hypervisor_id)
  end

  def delete_disk disk
    Wvm::Machine.delete_disk disk, self, Hypervisor.find(hypervisor_id)
  end

  def mount_iso iso_image
    Wvm::Machine.mount_iso self, iso_image, Hypervisor.find(hypervisor_id)
  end

  def iso_distro
    Plans::IsoDistro.find @iso_distro_id if @iso_distro_id
  end

  def iso_image
    Plans::IsoImage.find @iso_image_id if @iso_image_id
  end

  def delete
    Wvm::Machine.delete self , Hypervisor.find(hypervisor_id)
  end

  class Status < ActiveHash::Base
    # TODO: https://github.com/pluginaweek/state_machine

    self.data = [
        {id: :running, name: 'Running', running: true, icon: 'play'},
        {id: :saved, name: 'Saved', running: false, icon: 'stop'},
        {id: :suspended, name: 'Paused', running: false, icon: 'pause'},
        {id: :stopped, name: 'Stopped', running: false, icon: 'stop'},
        {id: :unknown, name: 'Unknown', running: nil, icon: 'question'}
    ]

    def stopped?
      running === false
    end

    def running?
      running
    end

    def to_s
      name
    end
  end
end
