class SpaController < AfterSetupController
  include Hooks
  define_hook :on_render_home

  helper_method :run_render_home_hook

  respond_to :html

  def run_render_home_hook
    run_hook(:on_render_home).join('').html_safe
  end

  before_action do
    @navbar_links = []
  end

  before_action :authenticate_user!

  before_action do
    @navbar_links = []
  end

  def home
    @disk = Infra::Disk.new
    @iso_images = Plans::IsoImage.all
    @isos = Plans::IsoDistro.all
    @plans ||= Defaults::MachinePlan.all
  end
end