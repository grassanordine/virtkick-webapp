class User < ActiveRecord::Base
  include Hooks
  define_hook :post_create_user

  devise :database_authenticatable, :rememberable, :trackable

  has_many :meta_machines, dependent: :destroy
  has_many :new_machines, dependent: :destroy
  has_many :progresses, dependent: :destroy

  auto_strip_attributes :email

  scope :guest, -> {
    where(guest: true)
  }

  scope :to_delete, -> {
    timeout = Rails.configuration.x.demo_timeout || raise('DEMO_TIMEOUT not set')
    guest.where('created_at < ?', timeout.minutes.ago)
  }


  def self.create_guest!
    email = "guest_#{SecureRandom.uuid}@alpha.virtkick.io"
    create_user! email, guest: true
  end

  def self.create_single_user!
    email = 'user@alpha.virtkick.io'
    user = User.where(email: email).first
    return user if user
    create_user! email
  end

  def self.create_private_user! email, password
    create_user! email, password: password, validate: true
  end

  def machines
    meta_machines.not_deleted.map &:machine
  end

  def remember_me
    true
  end

  def to_s
    "User #{id}: #{email}"
  end

  private
  def self.create_user! email, password: nil, guest: false, validate: false
    user = User.new \
        email: email,
        password: password,
        guest: guest
    user.save validate: validate
    user
  end
end
