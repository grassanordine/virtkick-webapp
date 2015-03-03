class SpaController < AfterSetupController
  before_action :authenticate_user!

  helper_method :inject_module
  helper_method :object_to_json_constant
  helper_method :setting_to_json_constant

  def object_to_json_constant name, object, class_name = 'constant'
    locals = {id: name.camelize(:lower), value: object.to_json, class_name: class_name}

    str = render_to_string file: 'helpers/object_to_json_constant' , locals: locals, layout: nil
    str
  end

  def setting_to_json_constant name
    @val = Setting.get name
    object_to_json_constant name.camelize(:lower), @val
  end

  def inject_module name
    object_to_json_constant "inject_module_#{name}", name, 'inject-module'
  end

  respond_to :html

  def home
    authenticate_user!

    @disk_types = Infra::DiskType.all 1
    @disk = Infra::Disk.new
    @iso_images = Plans::IsoImage.all
    @isos = Plans::IsoDistro.all
    @plans ||= Defaults::MachinePlan.all
  end
end