class Setting < ActiveRecord::Base
  def self.find_by_key key, default = nil
    val = Setting.where(key: key).first.try(:val)
    val.nil? ? default : val
  end

  def self.set_by_key key, value
    key.downcase!
    setting = Setting.find_by key: key
    if setting
      setting.val = value
      setting.save!
    else
      Setting.create! key: key, val: value
    end
  end

  def self.get name
    if Rails.env.development?
      find_by_key(name) || ENV['VIRTKICK_' + name.upcase]
    else
      find_by_key name
    end
  end
end
