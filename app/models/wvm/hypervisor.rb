class Wvm::Hypervisor < ActiveYaml::Base
  set_root_path "#{Rails.root}"
  set_filename 'config/hypervisors'
end