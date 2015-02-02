class Setting < ActiveRecord::Base
  def self.find_by_key key, default = nil
    val = Setting.where(key: key).first.try(:val)
    val.nil? ? default : val
  end
end
