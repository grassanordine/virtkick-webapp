class Ip < ActiveRecord::Base
  # belongs_to :machine # TODO
  belongs_to :ip_range
  belongs_to :meta_machine

  scope :not_taken, -> {
    where meta_machine_id: nil
  }
  scope :taken, -> {
    where.not meta_machine_id: nil
  }
  scope :ip_to_take, -> {
    not_taken.limit 1
  }

end
