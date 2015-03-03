class SetupController < ApplicationController
  layout 'raw'


  def index
    return redirect if @@ready
    self.class.check
    redirect
  rescue Wvm::Setup::Error, ModeSetup::Error
    render action: :index
  end

  def perform
    self.class.check
    render action: 'index'
  rescue Wvm::Setup::Error, ModeSetup::Error
    begin
      Wvm::Hypervisor.all.each do |hypervisor|
        Wvm::Setup.setup hypervisor
      end
      puts params
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

    Wvm::Hypervisor.all.each do |hypervisor|
      Wvm::Setup.check hypervisor
    end
  end

  private

  def redirect
    @@ready = true
    redirect_to guests_path
    CountDeploymentJob.track CountDeploymentJob::SETUP_SUCCESS
  end
end
