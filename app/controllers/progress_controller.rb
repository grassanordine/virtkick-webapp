class ProgressController < ApiController
  before_action :authenticate_user!

  def progress
    progress = current_user.progresses.find params[:id]
    render json: progress
    if progress.finished
      #progress.destroy
    end
  end

  def machine
    new_machine = current_user.new_machines.find params[:id]
    render json: new_machine
    if new_machine.finished
      new_machine.destroy
    end
  end
end
