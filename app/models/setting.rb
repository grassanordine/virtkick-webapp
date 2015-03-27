class Setting < ActiveRecord::Base
  def self.get name
    if Rails.env.development? or Rails.env.test?
      find_by_key(name) || ENV['VIRTKICK_' + name.upcase]
    else
      find_by_key name
    end
  end

  def self.set key, val, temporary: false
    key = key.downcase

    if temporary
      raise 'Not allowed in production.' if Rails.env.production?
      ENV['VIRTKICK_' + key.upcase] = val
    else
      set_by_key key, val
    end
  end

  def self.find_by_key key, default = nil
    val = Setting.where(key: key).first.try(:val)
    val.nil? ? default : val
  end

  def self.set_by_key key, val
    key = key.downcase

    setting = Setting.find_by key: key
    if setting
      setting.val = val
      setting.save!
    else
      Setting.create! key: key, val: val
    end
  end
end
