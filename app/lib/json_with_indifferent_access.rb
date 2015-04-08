class JsonWithIndifferentAccess
  def self.load str
    obj = JSON.load str
    if obj.is_a? Array
      obj.map do |e|
        HashWithIndifferentAccess.new(e)
      end
    elsif obj
      HashWithIndifferentAccess.new(obj)
    end
  end

  def self.dump obj
    str = JSON.dump obj
    str
  rescue Encoding::UndefinedConversionError => e
    ''
  end
end
