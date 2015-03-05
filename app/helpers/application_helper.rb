module ApplicationHelper
  def object_to_json_constant name, object, class_name = 'constant'
    locals = {id: name.camelize(:lower), value: object.to_json, class_name: class_name}
    render_helper 'object_to_json_constant', locals
  end
  module_function :object_to_json_constant

  def setting_to_json_constant name
    val = Setting.get name
    object_to_json_constant name.camelize(:lower), val
  end
  module_function :setting_to_json_constant

  def inject_module name
    object_to_json_constant "inject_module_#{name}", name, 'inject-module'
  end
  module_function :inject_module


  def render_helper template, locals
    Slim::Template.new("app/views/helpers/#{template}.slim").render(nil, locals).html_safe
  end
  module_function :render_helper
end
