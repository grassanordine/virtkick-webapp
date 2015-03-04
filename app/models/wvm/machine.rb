require 'ipaddress'

class Wvm::Machine < Wvm::Base
  def self.all hypervisor_id
    response = call :get, "/#{hypervisor_id}/instances"
    build_all_instances response, hypervisor_id
  end

  def self.status id, hypervisor_id
    response = call :get, "/#{hypervisor_id}/status/#{id}"

    response[:machines].map do |machine|
      {
          status: determine_status(machine),
          hostname: machine[:hostname],
          memory: machine[:cur_memory],
          processors: machine[:vcpu],
          disks: Wvm::Disk.array_of(machine[:disks], hypervisor_id)
      }
    end
  end

  def self.find id, hypervisor_id
    response = call :get, "/#{hypervisor_id}/instance/#{id}"

    hypervisor_data = hypervisor hypervisor_id

    params = {
      processor_usage: response[:cpu_usage],
      hostname: response[:name],
      uuid: response[:uuid],
      memory: response[:cur_memory],
      processors: response[:vcpu],
      status: determine_status(response),
      vnc_port: response[:vnc_port],
      vnc_listen_ip: hypervisor_data[:vnc_listen_ip],
      vnc_password: response[:vnc_password],
      disks: Wvm::Disk.array_of(response[:disks], hypervisor_id),
      iso_dir: hypervisor_data[:iso][:path],
      hypervisor_id: hypervisor_id
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

  def self.create new_machine, hypervisor_id
    machine = build_new_machine new_machine, hypervisor_id

    template = File.dirname(__FILE__) + '/new_machine.xml.slim'
    xml = Slim::Template.new(template, format: :xhtml).render Object.new, {machine: machine}
    call :post, "/#{hypervisor_id}/create", create_xml: '',
        from_xml: xml

    machine = Infra::Machine.find machine.hostname, hypervisor_id

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
    define_singleton_method operation_name do |id, hypervisor_id|
      operation libvirt_name, id, hypervisor_id
    end
  end

  def self.force_restart id, hypervisor_id
    operation :destroy, id, hypervisor_id
    operation :start, id, hypervisor_id
  end

  def self.add_disk disk, machine, hypervisor_id
    disk.device = machine.disks.next_device_name
    Wvm::Disk.create disk, machine.uuid, hypervisor_id

    call :post, "/#{hypervisor_id}/instance/#{machine.hostname}", assign_volume: '',
        file: disk.path, device: disk.device
  end

  def self.delete_disk disk, machine, hypervisor_id
    call :post, "/#{hypervisor_id}/instance/#{machine.hostname}", unassign_volume: '',
        device: disk.device

    Wvm::Disk.delete disk, hypervisor_id
  end

  def self.mount_iso machine, iso_image, hypervisor_id
    call :post, "/#{hypervisor_id}/instance/#{machine.hostname}", mount_iso: '',
        media: iso_image.file # device purposely omitted
  end

  def self.delete machine, hypervisor_id
    call :post, "/#{hypervisor_id}/instance/#{machine.hostname}", delete: '',
        delete_disk: ''
  end


  private
  def self.sum_up object, &property
    object.map(&property).inject(0, &:+)
  end

  def self.operation operation, id, hypervisor_id
    call :post, "/#{hypervisor_id}/instances", operation => '', name: id
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

  def self.build_all_instances response, hypervisor_id
    machines = response.instances.map do |machine|
      Infra::Machine.new \
          hostname: machine[:name],
          memory: machine[:memory],
          disks: Wvm::Disk.array_of(machine.storage, hypervisor_id),
          status: determine_status(machine),
          hypervisor_id: hypervisor_id
    end
    machines.sort_by &:hostname
  end

  def self.build_new_machine new_machine, hypervisor_id
    uuid = SecureRandom.uuid
    networks = setup_networks uuid, hypervisor_id
    hypervisor_data = hypervisor(hypervisor_id)

    Infra::Machine.new \
        uuid: uuid,
        hostname: new_machine.hostname,
        memory: new_machine.plan.memory,
        processors: new_machine.plan.cpu,
        iso_distro_id: new_machine.iso_distro.id,
        iso_image_id: new_machine.iso_distro.iso_images.first.id,
        networks: networks,
        vnc_listen_ip: hypervisor_data[:vnc_listen_ip],
        vnc_password: SecureRandom.urlsafe_base64(32),
        iso_dir: hypervisor_data[:iso][:path],
        hypervisor_id: hypervisor_id
  end

  def self.setup_networks uuid, hypervisor_id
    networks = Infra::Networks.new
    hypervisor_data = hypervisor(hypervisor_id)
    networks.public = Infra::Network.new \
        pool_name: hypervisor_data[:network][:id],
        dhcp_network: IPAddress(hypervisor_data[:network][:address])
    networks
  end
end
