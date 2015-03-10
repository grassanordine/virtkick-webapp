class Hypervisor < ActiveRecord::Base

  serialize :network, JsonWithIndifferentAccess
  serialize :storages, JsonWithIndifferentAccess
  serialize :iso, JsonWithIndifferentAccess
  serialize :disk_types, JsonWithIndifferentAccess

  has_many :machines

  def self.bootstrap
    Wvm::Hypervisor.all.each do |wvm_hypervisor|
      host, port = wvm_hypervisor[:host].split ':'

      Hypervisor.create name: wvm_hypervisor[:name],
          host: host,
          port: port,
          login: wvm_hypervisor[:login],
          network: wvm_hypervisor[:network],
          storages: wvm_hypervisor[:storages],
          iso: wvm_hypervisor[:iso],
          setup: false
    end
  end
end