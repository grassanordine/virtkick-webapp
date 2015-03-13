module AssureRole
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!

    def self.assure_role key, *options
      around_filter lambda { |controller, block|
                      unless current_user.role == key.to_s
                        render json: {error: 'permission denied'}, status: 403
                        return
                      end
                      block.call
                    }, *options
    end
  end
end