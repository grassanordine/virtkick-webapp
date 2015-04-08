require 'ipaddress'

require 'app/models/hypervisor'

class Wvm::Setup < Wvm::Base
  class Error < Exception
  end

  def self.setup hypervisor
    handle_exceptions do
      id = create_connection_if_needed hypervisor
      hypervisor.wvm_id = id
      hypervisor.save

      networks = Array.wrap(hypervisor.network)
      networks.each do |network|
        create_network_if_needed hypervisor, network
      end

      all_storages(hypervisor).each do |storage|
        create_storage_if_needed hypervisor, storage
      end
      disk_types = Infra::DiskType.all(hypervisor).as_json
      hypervisor.disk_types = disk_types
      hypervisor.save
      id
    end
    # TODO: save response.hypervisor_id for future use
  end

  def self.check hypervisor
    handle_exceptions do
      id = find_connection hypervisor
      networks = Array.wrap(hypervisor.network)
      networks.each do |network|
        find_network hypervisor, network
      end
      all_storages(hypervisor).each do |storage|
        find_storage hypervisor, storage[:id]
      end
    end
  end

  private
  def self.handle_exceptions
    yield
  rescue Timeout::Error
    raise Error, \
        'Could not connect to the hypervisor. Is OpenSSH server running? Is libvirtd running? ' +
        'Can "virtkick" user execute virsh?'
  end

  # Connection

  def self.create_connection_if_needed hypervisor
    begin
      find_connection hypervisor
    rescue Exception
      create_connection hypervisor
    end
  end

  def self.find_connection hypervisor
    response = Timeout.timeout 1.second do
      call :get, '/servers'
    end

    host_info = response[:hosts_info].find do |host_info|
      host_info[:hostname] == hypervisor[:host]
    end

    if host_info.nil?
      raise Error, 'Libvirt connection not configured.' unless host_info
    elsif host_info[:status] != 1
      raise Timeout::Error
    else
      host_info[:id]
    end
  end

  def self.create_connection hypervisor

    Timeout.timeout 1.second do
      begin
        response = call :post, '/servers', host_del_by_name: '',
                        host_name: hypervisor.name,
                        name: hypervisor.name,
                        hostname: hypervisor.host,
                        login: hypervisor.login
      rescue => e
      end

      response = call :post, '/servers', host_ssh_add: '',
          name: hypervisor.name,
          hostname: hypervisor.host,
          login: hypervisor.login

      response[:id]
    end
  end

  # Network

  def self.create_network_if_needed hypervisor, network
    begin
      find_network hypervisor, network
    rescue Exception
      create_network hypervisor, network
    end
  end

  def self.find_network hypervisor, network

    network = call :get, "/#{hypervisor.wvm_id}/network/#{network[:id]}"
    if network[:state] != 1
      raise Errors, ['Network not active']
    end
  rescue Errors
    raise Error, 'Network not configured.'
  end

  def self.create_network hypervisor, network
    return if network[:type] == 'bridge' or network[:type] == 'direct'

    begin
      network_url = "/#{hypervisor.wvm_id}/network/#{network[:id]}"
      libvirt_network = call :get, network_url
    rescue Errors
      call :post, "/#{hypervisor.wvm_id}/networks", create: '',
          name: network[:id],
          subnet: network[:address],
          dhcp: network[:dhcp],
          forward: network[:type],
          bridge_name: '',
          dns: network[:dns].join(',')
    else
      if libvirt_network[:state] != 1
        call :post, network_url, start: ''
      end
      if libvirt_network[:autostart] != 1
        call :post, network_url, set_autostart: ''
      end
    end
  rescue Errors => e
    raise Error, "Error while creating a network: #{e.message}"
  end

  # Storage

  def self.create_storage_if_needed hypervisor, storage
    find_storage hypervisor, storage[:id]
  rescue Exception
    create_storage hypervisor, storage[:id], storage[:path]
  end

  def self.find_storage hypervisor, storage_id
    call :get, "/#{hypervisor.wvm_id}/storage/#{storage_id}"
  rescue Errors
    raise Error, 'Storage pools not configured'
  end

  def self.create_storage hypervisor, storage_id, storage_path
    call :post, "/#{hypervisor.wvm_id}/storages", create: '',
        stg_type: 'dir',
        name: storage_id,
        target: storage_path
  end

  def self.all_storages hypervisor
    hypervisor[:storages] + [hypervisor[:iso]]
  end
end
