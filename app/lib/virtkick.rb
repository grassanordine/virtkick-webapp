class Virtkick
  def self.mode
    Mode.get
  end

  def self.version
    '0.6.alpha' # TODO: git describe or something
  end
end