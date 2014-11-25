class MachinesController < ApplicationController
  before_action :authenticate_user!

  include FindMachine
  find_machine_before_action :id, except: [:index, :new, :create]

  respond_to :html
  respond_to :json, only: [:create, :show, :vnc]


  def index
    @machines = current_user.machines
    @new_machines = current_user.new_machines
  end

  def new
    @machine ||= NewMachine.new
    @plans ||= Defaults::MachinePlan.all
    @isos ||= Plans::IsoDistro.all
    respond_with @machine
  end

  def create

    machine_params = NewMachine.check_params params
    @machine = current_user.new_machines.build machine_params

    if params[:validate]
      @machine.valid?
      new
      return
    end

    if @machine.save
      MachineCreateJob.perform_later @machine.id
      redirect_to machines_path
      return
    end

    new
  end

  def show
    @disk_types = Infra::DiskType.all
    @disk = Infra::Disk.new
    @iso_images = Plans::IsoImage.all
    @isos = Plans::IsoDistro.all
    respond_with @machine
  end

  def destroy
    MachineDeleteJob.perform_later @meta_machine.id
    redirect_to machines_path
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
    if @machine.vnc_port
      render json: {port: @machine.vnc_port, host: @machine.vnc_listen_ip}
    else
      render json: {}, status: :precondition_failed
    end
  end
end
