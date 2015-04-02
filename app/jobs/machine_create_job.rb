class MachineCreateJob < TrackableJob
  include Hooks
  define_hooks :pre_create_machine
  define_hooks :post_create_machine

  self.set_max_attempts 1, 2.seconds

  def perform machine_id, hook_results
    job_initalize machine_id

    user = @machine.user
    hypervisor = @machine.hypervisor

    step :create_machine do

      run_hook :pre_create_machine, @machine.id, hook_results

      Infra::Machine.create @machine, hypervisor, user.email
      @machine.save!
      # TODO: extract disk create to a new step
    end

    step do
      run_hook :post_create_machine, @machine.id, hook_results
      MachineActionJob.perform_later user, @machine.id, 'start'
      @machine.finished = true
      @machine.save
    end

    @progress.data[:machine_id] = @machine.id
    CountDeploymentJob.track CountDeploymentJob::FIRST_VM_CREATE_SUCCESS
  end

  private
  def job_initalize machine_id
    @machine = MetaMachine.find machine_id
    unless @machine
      raise SafeException, 'Cannot create machine'
    end
  end

  def step step_name = nil
    if step_name
      @progress.data[step_name] = 'starting'
      @progress.save!
    end
    ret = yield
    if step_name
      @progress.data[step_name] = 'finished'
      @progress.save!
    end
    ret

  rescue Exception => e
    @machine.destroy!
    @progress.data[:finished] = true
    @progress.save!
    raise
  end
end
