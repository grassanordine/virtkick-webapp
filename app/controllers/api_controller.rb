class ApiController < AfterSetupController
  respond_to :json

  def ping
    render json: (Time.now.to_f * 1000).to_i
  end
end