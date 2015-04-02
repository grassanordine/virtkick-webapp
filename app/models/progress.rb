class Progress < ActiveRecord::Base
  serialize :data, JsonWithIndifferentAccess

  belongs_to :user

  after_initialize :defaults, unless: :persisted?

  def defaults
    self.data ||= {}
  end
end
