module AfterSetupOnly
  extend ActiveSupport::Concern

  included do
    before_action :after_setup_only

    private
    def after_setup_only
      ready = ApplicationController.class_variable_get :@@ready
      if ready and Virtkick.mode
        return
      end

      ApplicationController.class_variable_set :@@ready, false
      redirect_to setup_url
    end
  end
end
