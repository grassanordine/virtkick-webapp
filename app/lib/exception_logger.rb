class ExceptionLogger
  def self.log e
    puts '^^== BEGIN EXCEPTION'
    puts e.message
    puts e.backtrace.map { |e| '    ' + e }.join "\n"
    puts '__== END EXCEPTION'
  end
end
