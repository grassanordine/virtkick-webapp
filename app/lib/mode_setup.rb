class ModeSetup
  class Error < Exception
  end

  def self.check
    raise Error, 'Mode not set.' if Mode.none?
  end

  def self.setup params
    mode = params[:mode]
    if mode == 'localhost'
      setup_localhost
    elsif mode == 'demo'
      setup_demo
    elsif mode == 'private_cloud'
      setup_private_cloud params
    elsif mode == 'vps_provider'
      setup_vps_provider params
    else
      raise Error, 'Sorry - not a valid mode.'
    end
  end

  private
  def self.setup_localhost
    user = User.create_single_user!
    Wvm::Setup.import_from_libvirt user
    Mode.set 'localhost'
    user
  end

  def self.setup_demo
    Mode.set 'demo'
    nil
  end

  def self.setup_private_cloud extra
    email, password = extra[:email], extra[:password]

    user = User.create_private_user! email, password, type: 'admin'
    Wvm::Setup.import_from_libvirt user
    Mode.set 'private_cloud'
    user
  end

  def self.setup_vps_provider extra
    raise Error, 'Sorry - still working on this. Good try, though!'
  end
end
