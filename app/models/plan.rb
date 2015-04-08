class Plan < ActiveRecord::Base
  has_many :machines
  serialize :params, JsonWithIndifferentAccess

  scope :monthly, -> {
    where(period: 'monthly')
  }

  scope :hourly, -> {
    where(period: 'hourly')
  }

  def self.bootstrap
    return if Plan.count > 0
    Defaults::MachinePlan.all.each do |plan_def|
      Plan.create! price: plan_def[:price],
        period: plan_def[:period],
        currency: plan_def[:currency] || 'usd',
        params: {
            cpu: plan_def[:cpu],
            memory: plan_def[:memory],
            storage: plan_def[:storage],
            storage_type: plan_def[:storage_type]
        }
    end
  end
end