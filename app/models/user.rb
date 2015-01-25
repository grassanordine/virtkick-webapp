class User < ActiveRecord::Base
  devise :database_authenticatable, :rememberable, :trackable

  has_many :meta_machines, dependent: :destroy
  has_many :new_machines, dependent: :destroy
  has_many :progresses, dependent: :destroy

  scope :guest, -> {
    where(guest: true)
  }

  scope :to_delete, -> {
    timeout = Rails.configuration.x.demo_timeout || raise('DEMO_TIMEOUT not set')
    guest.where('created_at < ?', timeout.minutes.ago)
  }


  def self.create_guest!
    email = "guest_#{SecureRandom.uuid}@alpha.virtkick.io"
    create_user! email, true
  end

  def self.create_single_user!
    email = 'user@alpha.virtkick.io'
    user = User.where(email: email).first
    return user if user
    create_user! email, false
  end

  def self.create_user! email, guest
    user = User.new email: email, guest: guest
    user.save validate: false
    user
  end

  def machines
    Infra::Elements.new self.meta_machines.not_deleted.map &:machine
  end

  def remember_me
    true
  end

  def to_s
    "User #{id}: #{email}"
  end
end
