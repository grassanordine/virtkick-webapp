module Bugsnagable
  def error job, e
    if Rails.env.development?
      ExceptionLogger.log e
    end
  end

  def failure job, e
    unless Rails.env.test?
      ExceptionLogger.log e
    end
    Bugsnag.notify_or_ignore e
  end
end
