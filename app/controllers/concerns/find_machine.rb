module FindMachine
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!

    def self.find_machine_before_action key, *options
      around_filter lambda { |controller, block|
        @meta_machine = current_user.meta_machines.find params[key]
        block.call
      }, *options
    end
  end
end
