module DemoSessionLimiter
  extend ActiveSupport::Concern

  included do
    before_action :limit_demo_session

    private
    def limit_demo_session
      return unless Virtkick.mode.demo?
      @demo_timeout = Rails.configuration.x.demo_timeout

      return unless user_signed_in?
      if current_user.guest? and current_user.created_at <= @demo_timeout.minutes.ago
        sign_out
        flash[:alert] = "Demo sessions are limited to #{@demo_timeout} minutes.\n Start again if you wish! :-)"
        redirect_to '/'
      end
    end
  end
end
