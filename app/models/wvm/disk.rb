class Wvm::Disk < Wvm::Base
  def self.array_of disks, hypervisor
    disks ||= []
    array = disks.map do |disk|
      local_pool = Wvm::StoragePool.to_local disk[:storage], hypervisor
      local_pool_name = local_pool ? local_pool[:name] : nil
      # TODO: This introduces a security hole. We should allow to get a disk from a custom storage pool, but we
      # shouln't accept it when creating. Storage pool validation should occur on Controller level, not Infra level.

      Infra::Disk.new \
          used: disk[:allocation],
          size: disk[:capacity],
          device: disk[:dev],
          path: disk[:path],
          name: disk[:image],
          format: disk[:format],
          type: local_pool_name,
          pool: disk[:storage]
    end

    Infra::Disks.new array
  end

  def self.create disk, uuid, hypervisor
    raise unless disk.pool =~ /\A[a-zA-Z-]+\Z/

    add_missing_fields disk, uuid, hypervisor

    gigabytes = disk.size / 1.gigabytes
    meta_prealloc = disk.format == 'qcow2'

    call :post, "/#{hypervisor.wvm_id}/storage/#{disk.pool}", add_volume: '',
        name: disk.name, size: gigabytes, format: disk.format, meta_prealloc: meta_prealloc
  end

  def self.delete disk, hypervisor
    call :post, "/#{hypervisor[:wvm_id]}/storage/#{disk.pool}", del_volume: '',
        volname: disk.name
  end

  def self.add_missing_fields disk, uuid, hypervisor
    disk.format ||= 'qcow2'
    disk.name = uuid + '_' + disk.device + '.' + disk.format # TODO: introduce subdirectory per VM
    pool = Wvm::StoragePool.find disk.pool, hypervisor
    disk.path = pool.path + '/' + disk.name
  end
end
