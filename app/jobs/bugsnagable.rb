module Bugsnagable
  def error job, e
    if Rails.env.development?
      print_exception e
    end
  end

  def failure job, e
    unless Rails.env.test?
      print_exception e
    end
    Bugsnag.notify_or_ignore e
  end

  private

  def print_exception e
    puts '^^== BEGIN EXCEPTION'
    puts e.message
    puts e.backtrace.map { |e| '    ' + e }.join "\n"
    puts '__== END EXCEPTION'
  end
  module_function :print_exception
end
