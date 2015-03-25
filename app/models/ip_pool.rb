require 'ipaddress'

class IpPool < ActiveRecord::Base
  has_many :ips, dependent: :destroy

  has_and_belongs_to_many :hypervisors

  before_destroy :assure_not_taken, prepend: true
  after_create :populate_ips

  validate do |ip_pool|
    ip_address = IPAddress ip_pool.network
    gateway_ip_address = IPAddress(ip_pool.gateway)
    if ip_address.network.prefix == 32
      ip_pool.errors.add :network, 'is not a network'
    elsif not ip_address.include? gateway_ip_address
      ip_pool.errors.add :gateway, "is not inside network #{ip_pool.network}"
    elsif gateway_ip_address.octets.last == 0 or gateway_ip_address.octets.last == 255
      ip_pool.errors.add :gateway, 'is not a host address'
    end
  end


  def self.find_free
    self.ips.find_by(meta_machine_id: nil)
  end

  def self.allocate_for meta_machine
    ip = self.find_free
    unless ip
      raise SafeException, 'IP pool is exhausted'
    end
    ip.meta_machine_id = meta_machine.id
    ip.save!
  end

  private

  def populate_ips
    Ip.transaction do
      IPAddress(network).each_host do |host|
        host_string = host.to_s
        next if host_string == gateway
        self.ips.create(ip: host_string)
      end
    end
  end

  def assure_not_taken
    ips.taken.count == 0
  end
end
