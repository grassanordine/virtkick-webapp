class GuestsController < AfterSetupController
  layout 'raw'

  respond_to :html

  def render_home
    render_action_in_other_controller SpaController, :home, params
  end

  around_action { |controller, block|
    if user_signed_in?
      render_home
    else
      block.call
    end
  }

  def index
    if Virtkick.mode.localhost?
      sign_in User.create_single_user!
      render_home
    elsif Virtkick.mode.demo?
      render action: 'index_demo'
    else
      render_home
    end
  end

  def create
    raise unless Virtkick.mode.demo?

    sign_in User.create_guest!
    render_home
  end
end
