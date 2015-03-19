require 'active_hash'

class Infra::DiskType < Infra::Base
  attr_accessor :id
  attr_accessor :name
  attr_accessor :path # extract to FileDiskType
  attr_accessor :enabled

  def self.all hypervisor
    Wvm::StoragePool.all hypervisor
  end

  def self.find id, hypervisor
    Wvm::StoragePool.find id, hypervisor
  end
end
