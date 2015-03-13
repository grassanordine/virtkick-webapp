require 'ipaddress'
require 'app/models/hypervisor'

class Wvm::Machine < Wvm::Base
  def self.all hypervisor
    response = call :get, "/#{hypervisor[:wvm_id]}/instances"
    build_all_instances response, hypervisor
  end

  def self.status payload
    response = call :post, '/status', json: payload

    response[:machines].map do |machine|
      begin
        hypervisor = ::Hypervisor.find_by(wvm_id: machine[:hypervisor_id])
        {
            status: determine_status(machine),
            hostname: machine[:hostname],
            memory: machine[:cur_memory],
            processors: machine[:vcpu],
            disks: Wvm::Disk.array_of(machine[:disks], hypervisor)
        }
      end
    end.compact
  end

  def self.find id, hypervisor
    response = call :get, "/#{hypervisor[:wvm_id]}/instance/#{id}"

    params = {
      processor_usage: response[:cpu_usage],
      hostname: response[:name],
      uuid: response[:uuid],
      memory: response[:cur_memory],
      processors: response[:vcpu],
      status: determine_status(response),
      vnc_port: response[:vnc_port],
      vnc_listen_ip: hypervisor[:host],
      vnc_password: response[:vnc_password],
      mac_address: response[:mac_address],
      disks: Wvm::Disk.array_of(response[:disks], hypervisor),
      iso_dir: hypervisor[:iso][:path],
      hypervisor_id: hypervisor[:id]
    }

    if response[:media] and not response[:media].empty?
      file = response[:media].first[:image]
      iso_image = Plans::IsoImage.by_file(file).first

      if iso_image
        params[:iso_image_id] = iso_image.id
        params[:iso_distro_id] = iso_image.iso_distro.id
      end
    end

    Infra::Machine.new params
  end

  def self.create new_machine, hypervisor
    machine = build_new_machine new_machine, hypervisor

    template = File.dirname(__FILE__) + '/new_machine.xml.slim'
    xml = Slim::Template.new(template, format: :xhtml).render Object.new, {
        machine: machine,
        hypervisor: hypervisor
    }

    call :post, "/#{hypervisor[:wvm_id]}/create", create_xml: '',
        from_xml: xml

    machine = Infra::Machine.find machine.hostname, hypervisor

    machine.create_disk Infra::Disk.new \
        size: new_machine.plan.storage,
        pool: new_machine.plan.storage_type

    machine
  end

  OPERATIONS = {
      start: :start,
      pause: :suspend,
      resume: :resume,
      stop: :shutdown,
      force_stop: :destroy,
      restart: :restart
  }

  OPERATIONS.each do |operation_name, libvirt_name|
    define_singleton_method operation_name do |id, hypervisor|
      operation libvirt_name, id, hypervisor
    end
  end

  def self.force_restart id, hypervisor
    operation :destroy, id, hypervisor
    operation :start, id, hypervisor
  end

  def self.add_disk disk, machine, hypervisor
    disk.device = machine.disks.next_device_name
    Wvm::Disk.create disk, machine.uuid, hypervisor

    call :post, "/#{hypervisor.wvm_id}/instance/#{machine.hostname}", assign_volume: '',
        file: disk.path, device: disk.device
  end

  def self.delete_disk disk, machine, hypervisor
    call :post, "/#{hypervisor.wvm_id}/instance/#{machine.hostname}", unassign_volume: '',
        device: disk.device

    Wvm::Disk.delete disk, hypervisor
  end

  def self.mount_iso machine, iso_image, hypervisor
    call :post, "/#{hypervisor.wvm_id}/instance/#{machine.hostname}", mount_iso: '',
        media: iso_image.file # device purposely omitted
  end

  def self.delete machine, hypervisor
    call :post, "/#{hypervisor.wvm_id}/instance/#{machine.hostname}", delete: '',
        delete_disk: ''
  end


  private
  def self.sum_up object, &property
    object.map(&property).inject(0, &:+)
  end

  def self.operation operation, id, hypervisor
    call :post, "/#{hypervisor[:wvm_id]}/instances", operation => '', name: id
  end

  def self.determine_status response
    status = case response[:status]
      when 1
        :running
      when 3
        :suspended
      when 5
        response[:has_managed_save_image] == 1 ? :saved : :stopped
      else
        :unknown
    end
    Infra::Machine::Status.find status
  end

  def self.build_all_instances response, hypervisor
    machines = response[:instances].map do |machine|
      Infra::Machine.new \
          hostname: machine[:name],
          memory: machine[:memory],
          disks: Wvm::Disk.array_of(machine[:storage], hypervisor),
          status: determine_status(machine),
          hypervisor_id: hypervisor[:wvm_id]
    end
    machines.sort_by &:hostname
  end

  def self.random_mac_address
    ('%02x'%((rand 64)*4|2)) + (0..4).inject(''){|s,x|s+':%02x'%(rand 256)}
  end

  def self.build_new_machine new_machine, hypervisor
    uuid = SecureRandom.uuid
    networks = setup_networks uuid, hypervisor

    Infra::Machine.new \
        uuid: uuid,
        hostname: new_machine.hostname,
        memory: new_machine.plan.memory,
        processors: new_machine.plan.cpu,
        iso_distro_id: new_machine.iso_distro.id,
        iso_image_id: new_machine.iso_distro.iso_images.first.id,
        mac_address: random_mac_address,
        networks: networks,
        vnc_listen_ip: hypervisor[:host],
        vnc_password: SecureRandom.urlsafe_base64(32),
        iso_dir: hypervisor[:iso][:path],
        hypervisor_id: hypervisor[:wvm_id]
  end

  def self.setup_networks uuid, hypervisor
    networks = Infra::Networks.new
    return if hypervisor[:network][:type] == 'bridge'

    networks.public = Infra::Network.new \
        pool_name: hypervisor[:network][:id],
        dhcp_network: IPAddress(hypervisor[:network][:address])
    networks
  end
end
