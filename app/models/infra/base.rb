class Infra::Base
  include ActiveModel::Model
  include ActiveModel::AttributeMethods

  def persisted?
    self.id.present?
  end

  def to_s
    inspect
  end

  def as_json config = {}
    self.instance_values.as_json config
  end
end
