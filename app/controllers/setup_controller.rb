class SetupController < ApplicationController
  layout 'raw'


  def index
    return redirect if @@ready
    check
    redirect
  rescue Wvm::Setup::Error, ModeSetup::Error
    render action: :index
  end

  def perform
    check
    render action: 'index'
  rescue Wvm::Setup::Error, ModeSetup::Error
    begin
      Wvm::Hypervisor.all.each do |hypervisor|
        Wvm::Setup.setup hypervisor
      end

      user = ModeSetup.setup params[:mode], params[:extra]
      sign_in user if user
      flash[:success] = 'All configured - start VirtKicking now! :-)'
      redirect
    rescue Wvm::Setup::Error => e
      @error = e.message
      render action: :index
    end
  end

  def recheck
    @@ready = false
    index
  end

  private
  def check
    ModeSetup.check

    Wvm::Hypervisor.all.each do |hypervisor|
      Wvm::Setup.check hypervisor
    end
  end

  def redirect
    @@ready = true
    redirect_to guests_path
    CountDeploymentJob.track CountDeploymentJob::SETUP_SUCCESS
  end
end
