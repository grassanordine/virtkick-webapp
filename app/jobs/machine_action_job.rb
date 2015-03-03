class MachineActionJob < TrackableJob
  self.set_max_attempts 1, 2.seconds

  def perform meta_machine_id, action
    machine = MetaMachine.find meta_machine_id
    machine.public_send action

    if action == 'start'
      CountDeploymentJob.track CountDeploymentJob::FIRST_VM_START_SUCCESS
    end
  end
end
