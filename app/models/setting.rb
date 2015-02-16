class Setting < ActiveRecord::Base
  def self.find_by_key key, default = nil
    val = Setting.where(key: key).first.try(:val)
    val.nil? ? default : val
  end

  def self.get name
    if Rails.env.development?
      find_by_key(:val) || ENV['VIRTKICK_' + name.upcase]
    else
      find_by_key :val
    end
  end
end
