module FindMachine
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!

    def self.find_machine_before_action key, *options
      @@find_machine_key = key
      def find_meta_machine
        @meta_machine = current_user.meta_machines.find params[@@find_machine_key]
        yield
      rescue ActiveRecord::RecordNotFound
        render json: {error: 'machine not found'}
      end

      around_filter :find_meta_machine, *options
    end
  end
end
