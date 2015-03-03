class ApplicationController < ActionController::Base
  include RequirejsHelper

  include Hooks
  define_hook :on_render_home

  helper_method :run_render_home_hook

  def run_render_home_hook
    run_hook(:on_render_home).join("").html_safe
  end

  protect_from_forgery with: :exception


  helper_method :object_to_json_constant
  helper_method :setting_to_json_constant
  helper_method :inject_module

  def inject_module name
    object_to_json_constant "inject_module_#{name}", name, 'inject-module'
  end

  def object_to_json_constant name, object, class_name = 'constant'
    locals = {id: name.camelize(:lower), value: object.to_json, class_name: class_name}

    str = render_to_string file: 'helpers/object_to_json_constant' , locals: locals, layout: nil
    str
  end

  def setting_to_json_constant name
    @val = Setting.get name
    object_to_json_constant name.camelize(:lower), @val
  end


  @@ready ||= false

  ## Uncomment to debug requests
  # before_action do
  #   puts request.headers.inspect
  # end

  before_action do
    @navbar_links = []
  end

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

  def home
    authenticate_user!

    @disk_types = Infra::DiskType.all 1
    @disk = Infra::Disk.new
    @iso_images = Plans::IsoImage.all
    @isos = Plans::IsoDistro.all
    @plans ||= Defaults::MachinePlan.all
  end

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
