class SetupController < ApplicationController
  layout 'raw'

  def index
    return redirect if @@ready
    self.class.check
    redirect
  rescue Wvm::Setup::Error
    self.class.setup_hypervisors
    redirect
  rescue ModeSetup::Error
    render action: :index
  end

  def self.setup_hypervisors
    Hypervisor.bootstrap
    Hypervisor.all.each do |hypervisor|
      hypervisor.setup import_machines: true
    end
  end

  def perform
    self.class.check
    render action: 'index'
  rescue Wvm::Setup::Error, ModeSetup::Error
    begin
      user = ModeSetup.setup params
      sign_in user if user
      self.class.setup_hypervisors
      render json: {success: 'All configured - start VirtKicking now! :-)'}
    rescue Wvm::Setup::Error => e
      render json: {error: e.message}, status: 500
    end
  end

  def self.check
    ModeSetup.check
  end

  private

  def redirect
    @@ready = true
    CountDeploymentJob.track CountDeploymentJob::SETUP_SUCCESS
    render_action_in_other_controller GuestsController, :index, params
  end
end
