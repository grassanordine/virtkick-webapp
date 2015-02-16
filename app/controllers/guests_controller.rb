class GuestsController < AfterSetupController
  layout 'raw'

  before_action do
    redirect_to machines_path if user_signed_in?
  end


  def index
    if Virtkick.mode.localhost?
      sign_in User.create_single_user!
      redirect_to machines_path
    elsif Virtkick.mode.demo?
      render action: 'index_demo'
    else
      redirect_to machines_path
    end
  end

  def create
    raise unless Virtkick.mode.demo?

    sign_in User.create_guest!
    redirect_to machines_path
  end
end
