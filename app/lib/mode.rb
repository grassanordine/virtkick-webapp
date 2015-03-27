class Mode
  MODES = %w(localhost demo private_cloud vps_provider)

  def self.get
    mode = Setting.get :mode
    mode ? ActiveSupport::StringInquirer.new(mode) : nil
  end

  def self.set new_mode
    raise unless MODES.include? new_mode

    mode = Setting.find_or_initialize_by key: 'mode'
    mode.update val: new_mode
  end

  def self.none?
    Setting.get(:mode).nil?
  end
end
