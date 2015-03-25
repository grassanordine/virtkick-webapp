class Hypervisor < ActiveRecord::Base

  serialize :network, JsonWithIndifferentAccess
  serialize :storages, JsonWithIndifferentAccess
  serialize :iso, JsonWithIndifferentAccess
  serialize :disk_types, JsonWithIndifferentAccess
  serialize :spec, JsonWithIndifferentAccess

  has_and_belongs_to_many :ip_pools
  has_many :meta_machines

  def self.find_best_hypervisor plan
    found = Hypervisor.order('random()').first
    unless found
      raise 'No capacity left to create new machines at this time, please come back later! Sorry :-('
    end
    found
  end

  def self.bootstrap
    if Virtkick.mode.vps_provider? and not ENV['VIRTKICK_BOOTSTRAP']
      return
    end

    Wvm::Hypervisor.all.each do |wvm_hypervisor|
      host, port = wvm_hypervisor[:host].split ':'

      Hypervisor.create name: wvm_hypervisor[:name],
          host: host,
          port: port,
          login: wvm_hypervisor[:login],
          network: wvm_hypervisor[:network],
          storages: wvm_hypervisor[:storages],
          iso: wvm_hypervisor[:iso],
          is_setup: false
    end
  end

  def bridge
    Array.wrap(network).find { |c| c[:type] == 'bridge' }
  end

  def nat
    Array.wrap(network).find { |c| c[:type] == 'nat' }
  end

  def route
    Array.wrap(network).find { |c| c[:type] == 'route' }
  end

  def setup import_machines: false
    begin
      Wvm::Setup.check self
    rescue Wvm::Setup::Error
      Wvm::Setup.setup self
    end

    if import_machines
      importer = LibvirtImporter.new
      importer.import_all self
    end
    update is_setup: true
  end
end