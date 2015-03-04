require 'ipaddress'

class Wvm::Setup < Wvm::Base
  class Error < Exception
  end

  def self.setup hypervisor
    handle_exceptions do
      id = create_connection_if_needed hypervisor
      hypervisor.id = id
      hypervisor.save

      create_network_if_needed id
      all_storages(id).each do |storage|
        create_storage_if_needed id, storage
      end
      id
    end
    # TODO: save response.hypervisor_id for future use
  end

  def self.check hypervisor
    handle_exceptions do
      id = find_connection hypervisor
      find_network id
      all_storages(id).each do |storage|
        find_storage id, storage[:id]
      end
    end
  end

  def self.import_from_libvirt user
    importer = LibvirtImporter.new
    importer.import_all user
  end

  private
  def self.handle_exceptions
    yield
  rescue Timeout::Error
    raise Error, \
        'Could not connect to localhost hypervisor. Is OpenSSH server running? Is libvirtd running? ' +
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
      response = call :post, '/servers', host_ssh_add: '',
          name: hypervisor.name,
          hostname: hypervisor.host,
          login: hypervisor.login

      response.id
    end
  end

  # Network

  def self.create_network_if_needed hypervisor_id
    begin
      find_network hypervisor_id
    rescue Exception
      create_network hypervisor_id
    end
  end

  def self.find_network hypervisor_id
    hypervisor_data = hypervisor hypervisor_id

    network = call :get, "/#{hypervisor_id}/network/#{hypervisor_data[:network][:id]}"
    if network[:state] != 1
      raise Errors, ['Network not active']
    end
  rescue Errors
    raise Error, 'Network not configured.'
  end

  def self.create_network hypervisor_id
    hypervisor_data = hypervisor hypervisor_id
    network = hypervisor_data[:network]

    begin
      network_url = "/#{hypervisor_id}/network/#{hypervisor_data[:network][:id]}"
      libvirt_network = call :get, network_url
    rescue Errors
      call :post, "/#{hypervisor_id}/networks", create: '',
          name: network[:id],
          subnet: network[:address],
          dhcp: network[:dhcp],
          forward: network[:type],
          bridge_name: '',
          dns: network[:dns].join(',')
    else
      if libvirt_network.state != 1
        call :post, network_url, start: ''
      end
      if libvirt_network.autostart != 1
        call :post, network_url, set_autostart: ''
      end
    end
  rescue Errors => e
    raise Error, "Error while creating a network: #{e.message}"
  end

  # Storage

  def self.create_storage_if_needed hypervisor_id, storage
    begin
      find_storage hypervisor_id, storage[:id]
    rescue Exception
      create_storage hypervisor_id, storage[:id], storage[:path]
    end
  end

  def self.find_storage hypervisor_id, storage_id
    call :get, "/#{hypervisor_id}/storage/#{storage_id}"
  rescue Errors
    raise Error, 'Storage pools not configured'
  end

  def self.create_storage hypervisor_id, storage_id, storage_path
    call :post, "/#{hypervisor_id}/storages", create: '',
        stg_type: 'dir',
        name: storage_id,
        target: storage_path
  end

  def self.all_storages hypervisor_id
    hypervisor_data = hypervisor hypervisor_id
    hypervisor_data[:storages] + [hypervisor_data[:iso]]
  end
end
