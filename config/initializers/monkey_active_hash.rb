class ActiveHash::Base
  def as_json options = {}
    attributes
  end
end
