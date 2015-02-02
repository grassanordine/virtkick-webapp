class Setting < ActiveRecord::Base
  def self.find_by_key key, default = nil
    Setting.where(key: key).first.try(:val)
  end
end
