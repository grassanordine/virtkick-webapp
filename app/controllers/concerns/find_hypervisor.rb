module FindHypervisor
  extend ActiveSupport::Concern

  included do
    include AssureRole
    assure_role :admin

    def self.find_hypervisor_before_action key, *options
      around_filter lambda { |controller, block|
                      begin
                        @hypervisor = Hypervisor.find(params[key] || params[key.to_s])
                      rescue Exception => e
                        raise SafeException, 'Cannot find hypervisor with given id'
                      end
                      block.call
                    }, *options
    end
  end
end
