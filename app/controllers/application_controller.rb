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
      if Rails.configuration.consider_all_requests_local
        render json: {exception: e.class.name, message: e.message}, status: 500
      else
        render json: {exception: true}, status: 500
      end

      puts e.message
      e.backtrace.each do |line|
        puts line
      end
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

  def render_progress progress_id, custom_data = nil
    raise 'Not an ID. Make sure Job returns a Numeric - or use TrackableJob.' unless progress_id.is_a? Numeric
    render json: {progress_id: progress_id, data: custom_data}
  end
end
