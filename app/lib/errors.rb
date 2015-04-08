class Errors < StandardError
  attr_reader :errors

  def initialize errors
    @errors = errors
  end

  def message
    if @errors.is_a? String
      @errors.message
    elsif @errors.size == 1
      @errors.first.to_s
    else
      @errors.map(&:to_s).to_s
    end
  end
end
