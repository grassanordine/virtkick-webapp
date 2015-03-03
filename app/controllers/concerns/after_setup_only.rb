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

      begin
        SetupController.check
        ApplicationController.class_variable_set :@@ready, true
      rescue Wvm::Setup::Error, ModeSetup::Error
        puts "NOT SETUP"
        respond_to do |format|
          format.html {
            puts "DD"
            redirect_to setup_url
          }
          format.json {
            render json: {error: 'Not set up'}
          }
        end
      end
    end
  end
end
