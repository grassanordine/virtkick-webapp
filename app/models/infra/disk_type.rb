require 'active_hash'

class Infra::DiskType < Infra::Base
  attr_accessor :id
  attr_accessor :name
  attr_accessor :path # extract to FileDiskType
  attr_accessor :enabled


  def self.all hypervisor_id
    Wvm::StoragePool.all hypervisor_id
  end

  def self.find id, hypervisor_id
    Wvm::StoragePool.find id, hypervisor_id
  end
end
