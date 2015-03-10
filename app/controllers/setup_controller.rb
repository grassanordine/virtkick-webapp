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
      Wvm::Setup.setup hypervisor
    end
  end

  def perform
    self.class.check
    render action: 'index'
  rescue Wvm::Setup::Error, ModeSetup::Error
    begin
      self.class.setup_hypervisors
      user = ModeSetup.setup params
      sign_in user if user
      render json: {success: 'All configured - start VirtKicking now! :-)'}
    rescue Wvm::Setup::Error => e
      render json: {error: e.message}, status: 500
    end
  end

  def recheck
    @@ready = false
    index
  end

  def self.check
    ModeSetup.check
  end

  private

  def redirect
    @@ready = true
    redirect_to guests_path
    CountDeploymentJob.track CountDeploymentJob::SETUP_SUCCESS
  end
end
