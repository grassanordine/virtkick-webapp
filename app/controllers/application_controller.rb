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

      puts e.message
      e.backtrace.each do |line|
        puts line
      end
      Bugsnag.notify_or_ignore e
    else
      raise e
    end
  end

  helper_method :inject_module
  helper_method :object_to_json_constant
  helper_method :setting_to_json_constant

  def object_to_json_constant name, object, class_name = 'constant'
    locals = {id: name.camelize(:lower), value: object.to_json, class_name: class_name}

    render_to_string file: 'helpers/object_to_json_constant' , locals: locals, layout: nil
  end

  def setting_to_json_constant name
    @val = Setting.get name
    object_to_json_constant name.camelize(:lower), @val
  end

  def inject_module name
    object_to_json_constant "inject_module_#{name}", name, 'inject-module'
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
