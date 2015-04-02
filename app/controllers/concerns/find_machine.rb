module FindMachine
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!

    def self.find_machine_before_action key, *options
      around_filter lambda { |controller, block|
        begin
          @meta_machine = current_user.meta_machines.find params[key]
          block.call
        rescue Exception => e
          ExceptionLogger.log e
          raise SafeException, 'Cannot find machine with given id'
        end
      }, *options
    end
  end
end
