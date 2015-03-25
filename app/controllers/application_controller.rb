class ApplicationController < ActionController::Base
  include RequirejsHelper

  protect_from_forgery with: :exception

  @@ready ||= false

  ## Uncomment to debug requests
  # before_action do
  #   puts request.headers.inspect
  # end

  before_action do
    @@paths ||= Virtkick.engines.map { |e| File.dirname e }

    @@paths.each do |engine_path|
      prepend_view_path "#{engine_path}/app/views"
    end
  end

  problem_message = 'A problem occured, we\'ve already notified our engineers, sorry!'
  rescue_from Exception do |e|
    if e.is_a? ActionView::MissingTemplate
      if request.format == 'application/json'
        #e.message = 'API end-point did not render anything'
        render_exception e, problem_message
      else
        raise e
      end
    elsif e.is_a? SafeException
      if request.format == 'application/json'
        render json: {error:  e.message}, status: 500
      else
        raise e
      end
    else
      if request.format == 'application/json'
        status = 500
        status = 440 if e.is_a? ActionController::InvalidAuthenticityToken

        render_exception e, problem_message, status
      else
        raise e
      end
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

  def render_exception e, production_message, status = 500
    Bugsnag.notify_or_ignore e
    message = Rails.env.production? ? production_message : e.message

    puts '^^== BEGIN EXCEPTION'
    puts e.message
    puts e.backtrace.map { |e| '    ' + e }.join "\n"
    puts '__== END EXCEPTION'
    render json: {error: message}, status: status
  end

  def render_success
    render json: {status: 'success'}
  end

  def render_invalid obj
    render json: {errors: obj.errors}, status: :unprocessable_entity
  end
end
