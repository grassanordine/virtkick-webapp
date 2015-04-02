class MetaMachine < ActiveRecord::Base
  serialize :create_params, JsonWithIndifferentAccess

  belongs_to :user
  belongs_to :hypervisor
  has_many :ips, dependent: :nullify

  validates :hostname, presence: true, format: {with: /\A[a-zA-Z0-9\.]+\z/}
  # validates :hostname, uniqueness: { case_sensitive: false }
  validate :hostname_unique
  validates :plan_id, presence: true, numericality: {only_integer: true}

  scope :not_deleted, -> {
    where deleted: false
  }

  scope :finished, -> {
    where finished: true
  }

  after_destroy do
    if libvirt_machine_name
      force_stop rescue nil
      machine.delete
    end
  end

  def machine
    machine = Infra::Machine.find libvirt_machine_name, hypervisor
    machine.id = self.id
    machine
  end

  def create_disk disk
    Wvm::Machine.add_disk disk, self.machine, hypervisor
  end

  def mark_deleted
    run_hook :on_mark_deleted, self.id

    update_attribute :deleted, true
  end

  def self.create_machine hostname, user_id, hypervisor_id, libvirt_machine_name
    machine = MetaMachine.new \
        hostname: hostname,
        user_id: user_id,
        hypervisor_id: hypervisor_id,
        libvirt_machine_name: libvirt_machine_name,
        plan_id: 0, # TODO: make up something sensible here
        finished: true
    machine.save!
    machine
  end

  %w(start pause resume stop force_stop restart force_restart).each do |operation|
    define_method operation do
      Wvm::Machine.send operation, libvirt_machine_name, hypervisor
    end
  end


  def plan
    Defaults::MachinePlan.find plan_id if plan_id
  end

  def iso_distro
    Plans::IsoDistro.find create_params[:iso_distro_id] if create_params[:iso_distro_id]
  end

  def iso_image
    Plans::IsoImage.find create_params[:iso_image_id] if create_params[:iso_image_id]
  end

  def self.check_params params
    params = params.require(:machine).permit(:hostname, :plan_id, :iso_distro_id, :iso_image_id)
    params
  end

  private
  def hostname_unique
    return if persisted?
    if MetaMachine.where(hostname: hostname, user_id: user_id).count > 0
      errors.add :hostname, 'already exists'
    end
  end
end
