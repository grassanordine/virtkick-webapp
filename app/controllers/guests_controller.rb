class GuestsController < AfterSetupController
  layout 'raw'

  respond_to :html

  before_action do
    redirect_to '/machines' if user_signed_in?
  end


  def index
    if Virtkick.mode.localhost?
      sign_in User.create_single_user!
      redirect_to '/machines'
    elsif Virtkick.mode.demo?
      render action: 'index_demo'
    else
      redirect_to '/machines'
    end
  end

  def create
    raise unless Virtkick.mode.demo?

    sign_in User.create_guest!
    redirect_to '/machines'
  end
end
