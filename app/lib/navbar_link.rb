class NavbarLink
  attr_accessor :title
  attr_accessor :icon_class
  attr_accessor :state
  attr_accessor :priority

  def <=> other
    priority <=> other.priority
  end

  def initialize title, icon_class: nil, state: nil, priority: 0
    @title = title
    @icon_class = icon_class
    @state = state
    @priority = priority
  end

end