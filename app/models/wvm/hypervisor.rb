class Wvm::Hypervisor < ActiveYaml::Base
  set_root_path "#{Rails.root}"
  set_filename 'config/hypervisors'

  def self.find_best_hypervisor plan
    all.sample(1)[0]
  end
end