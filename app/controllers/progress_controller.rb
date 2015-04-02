class ProgressController < ApiController
  before_action :authenticate_user!

  def progress
    progress = current_user.progresses.find params[:id]
    render json: {
      finished: progress.finished,
      error: progress.error,
      data: progress.data
    }
    if progress.finished
      progress.destroy
    end
  end
end
