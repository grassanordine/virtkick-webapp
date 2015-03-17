class ApplicationController < ActionController::Base
  include RequirejsHelper

  protect_from_forgery with: :exception

  @@ready ||= false

  ## Uncomment to debug requests
  # before_action do
  #   puts request.headers.inspect
  # end

  before_action do
    @@paths ||= Dir['engines/*/*.gemspec'].map { |e| File.dirname e}

    @@paths.each do |engine_path|
      prepend_view_path "#{engine_path}/app/views"
    end
  end

  rescue_from Exception do |e|
    if request.format == 'application/json'
      status = 500

      status = 440 if e.is_a? ActionController::InvalidAuthenticityToken

      if Rails.configuration.consider_all_requests_local
        render json: {exception: e.class.name, message: e.message}, status: status
      else
        render json: {exception: true}, status: status
      end

      puts '^^== BEGIN EXCEPTION'
      puts e.message
      puts e.backtrace.map { |e| '    ' + e }.join "\n"
      puts '__== END EXCEPTION'

      Bugsnag.notify_or_ignore e
    else
      raise e
    end
  end

  before_bugsnag_notify :add_user_info_to_bugsnag

  private
  def add_user_info_to_bugsnag notif
    if user_signed_in?
      notif.user = {
          id: current_user.id,
          email: current_user.email
      }
    end
  end

  def render_action_in_other_controller controller, action, params
    c = controller.new
    c.params = params
    c.dispatch action, request
    c.process_action(action)
    render text: c.response.body
  end

  def render_progress progress_id, custom_data = nil
    raise 'Not an ID. Make sure Job returns a Numeric - or use TrackableJob.' unless progress_id.is_a? Numeric
    render json: {progress_id: progress_id, data: custom_data}
  end
end
