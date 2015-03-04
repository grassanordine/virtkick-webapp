class MachinesController < AfterSetupController
  before_action :authenticate_user!

  include Hooks
  define_hooks :pre_create_machine
  define_hooks :on_render_new
  define_hooks :on_destroy
  
  include FindMachine
  find_machine_before_action :id, except: [:index, :new, :create]

  respond_to :html
  respond_to :json

  def index
    # TODO: handle multiple hypervisors here
    @disk_types = Infra::DiskType.all 1
    @disk = Infra::Disk.new
    @iso_images = Plans::IsoImage.all
    @isos = Plans::IsoDistro.all
    @plans ||= Defaults::MachinePlan.all

    run_hook :on_render_new

    respond_to do |format|
      format.json {
        render json: {machines: current_user.machines}
      }
    end
  end

  def new
    index
  end

  def validate
    machine_params = NewMachine.check_params params
    @machine = current_user.new_machines.build machine_params

    valid = @machine.valid?
    render json: {errors: valid ? [] : @machine.errors}
  end

  def create
    machine_params = NewMachine.check_params params
    @machine = current_user.new_machines.build machine_params

    return validate if params[:validate]

    @machine.valid?

    hook_results = run_hook :pre_create_machine

    if @machine.save
      progress_id = MachineCreateJob.perform_later current_user, @machine.id, hook_results
      render_progress progress_id, @machine.id
      return
    end

    new
  end

  def power
    index
  end

  def console
    index
  end

  def storage
    index
  end

  def settings
    index
  end

  def show
    machine = @meta_machine.machine
    respond_with machine do |format|
      format.html { index }
      format.json {
        render json: machine
      }
    end
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
    render json: @machine.status.attributes
  end

  def vnc
    machine = @meta_machine.machine
    if machine.vnc_port
      render json: {port: machine.vnc_port, host: machine.vnc_listen_ip}
    else
      render json: {}, status: :precondition_failed
    end
  end
end
