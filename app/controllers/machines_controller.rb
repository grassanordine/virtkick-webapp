class MachinesController < ApiController
  before_action :authenticate_user!

  include Hooks
  define_hooks :pre_create_machine
  define_hooks :on_render_new
  define_hooks :on_destroy
  
  include FindMachine
  find_machine_before_action :id, except: [:index, :create]

  def index
    render json: {machines: current_user.machines}
  end

  def validate
    machine_params = MetaMachine.check_params params
    @machine = machine_from_params machine_params

    valid = @machine.valid?
    render json: {errors: valid ? [] : @machine.errors}
  end

  def create
    machine_params = MetaMachine.check_params params
    @machine = machine_from_params machine_params

    return validate if params[:validate]

    unless @machine.valid?
      render_invalid @machine
      return
    end

    hypervisor = Hypervisor.find_best_hypervisor @machine.plan
    @machine.hypervisor = hypervisor
    hook_results = run_hook :pre_create_machine
    if @machine.save
      render_progress MachineCreateJob.perform_later current_user, @machine.id, hook_results
      return
    end
    render_invalid @machine
  end

  def show
    machine = @meta_machine.machine.as_json.merge \
      hostname: @meta_machine.hostname,
      disk_types: @meta_machine.hypervisor.disk_types,
      ips: @meta_machine.ips.map { |ip|
        ip_pool = ip.ip_pool
        network_address = IPAddress(ip_pool.network)
        {
          address: ip.ip,
          gateway: ip_pool.gateway,
          netmask: network_address.netmask + '/' + network_address.prefix.to_s
        }
      }
    render json: machine
  rescue ActiveRecord::RecordNotFound
    raise SafeException, 'Machine not found'
  end

  def destroy
    run_hook :on_destroy

    @meta_machine.deleted = true
    @meta_machine.save

    MachineDeleteJob.perform_later @meta_machine.id
    render json: nil
  end

  %w(start pause resume stop force_stop restart force_restart).each do |operation|
    define_method operation do
      render_progress MachineActionJob.perform_later current_user, @meta_machine.id, operation
    end
  end

  def mount_iso
    iso_image_id = params[:machine][:iso_image_id]
    render_progress MachineMountIsoJob.perform_later current_user, @meta_machine.id, iso_image_id
  end

  def state
    render json: @machine.status
  end

  def vnc
    begin
      machine = @meta_machine.machine
    rescue ActiveRecord::RecordNotFound
      render json: {}, status: :precondition_failed
    end
    if machine.vnc_port
      render json: {port: machine.vnc_port, host: machine.vnc_listen_ip}
    else
      render json: {}, status: :precondition_failed
    end
  end

  private

  def machine_from_params machine_params
    current_user.meta_machines.build({
       hostname: machine_params[:hostname],
       plan_id: machine_params[:plan_id],
       create_params: {
         iso_distro_id: machine_params[:iso_distro_id],
         iso_image_id: machine_params[:iso_image_id]
       }
     })
  end
end
