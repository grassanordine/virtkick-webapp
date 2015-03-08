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

  def self.all hypervisor_id
    Wvm::Machine.all hypervisor_id
  end

  def self.find hostname, hypervisor_id
    Wvm::Machine.find hostname, hypervisor_id
  end

  def self.create new_machine, hypervisor_id
    Wvm::Machine.create new_machine, hypervisor_id
  end

  def id
    @id ||= MetaMachine.where(hostname: hostname).first.id
  end

  %w(start pause resume stop force_stop restart force_restart).each do |operation|
    define_method operation do |hypervisor_id|
      Wvm::Machine.send operation, hostname, hypervisor_id
    end
  end

  def create_disk disk
    Wvm::Machine.add_disk disk, self, hypervisor_id
  end

  def delete_disk disk
    Wvm::Machine.delete_disk disk, self, hypervisor_id
  end

  def mount_iso iso_image
    Wvm::Machine.mount_iso self, iso_image, hypervisor_id
  end

  def iso_distro
    Plans::IsoDistro.find @iso_distro_id if @iso_distro_id
  end

  def iso_image
    Plans::IsoImage.find @iso_image_id if @iso_image_id
  end

  def delete hypervisor_id
    Wvm::Machine.delete self, hypervisor_id
  end

  def as_json config

    self.instance_values['vnc_password'] = 'ddd'
    self.instance_values.as_json config
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
