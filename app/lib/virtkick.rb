class Virtkick
  def self.mode
    Mode.get
  end

  def self.version
    '0.6.alpha' # TODO: git describe or something
  end

  def self.engines path = '*.gemspec'
    base = File.dirname(__FILE__) + '/../..'

    Dir.chdir base do
      Dir["engines/*/#{path}"]
    end
  end
end
