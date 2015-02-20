class MachineCreateJob < TrackableJob
  include Hooks
  define_hooks :post_create_machine

  self.run_once

  def perform new_machine_id, hook_results
    job_initalize new_machine_id

    step :create_machine do
      Infra::Machine.create @new_machine
      # TODO: extract disk create to a new step
    end

    step do
      machine = MetaMachine.create_machine! \
          @new_machine.hostname, @new_machine.user_id, 1, @new_machine.hostname # TODO: support multiple hypervisors

      @new_machine.update_attributes! \
          given_meta_machine_id: machine.id,
          finished: true,
          current_step: nil
      run_hook :post_create_machine, machine.id, hook_results
    end

    CountDeploymentJob.track CountDeploymentJob::FIRST_VM_CREATE_SUCCESS
  end

  private
  def job_initalize new_machine_id
    @new_machine = NewMachine.find new_machine_id
    # @commited_credit = CommitedCredit.find commited_credit_id
  end

  def step step_name = nil
    @new_machine.update_attribute :current_step, step_name if step_name
    ret = yield
    @new_machine.update_attribute "step_#{step_name}", true if step_name
    ret
  rescue Exception => e
    message = e.respond_to?(:errors) ? e.errors.first : e.message
    @new_machine.update_attributes \
        error_message: message,
        current_step: nil,
        finished: true
    raise
  end
end
