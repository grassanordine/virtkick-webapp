describe IpPool do
  it 'should forbid adding gateway outside of network' do
    expect {
      IpPool.create! network: '10.0.1.0/24',
                     gateway: '10.0.2.1'
    }.to raise_exception ActiveRecord::RecordInvalid, /not inside network/

    IpPool.create! network: '10.0.1.0/24', gateway: '10.0.1.1'
  end

  it 'should add all ips except gateway' do
    ip_pool = IpPool.create! network: '10.0.1.2/24', gateway: '10.0.1.1'

    expect(ip_pool.ips.count).to eq 253
    expect(ip_pool.ips).to_not contain_exactly '10.0.1.1'
  end

  it 'should clean all ips after destroy' do
    ip_pool = IpPool.create! network: '10.0.1.2/24', gateway: '10.0.1.1'
    ip_pool.destroy!

    expect(Ip.all.count).to eq 0
  end

  it 'should not allow for destroy if ip is in use' do
    ip_pool = IpPool.create! network: '10.0.1.2/24', gateway: '10.0.1.1'

    Ip.all.first.update! meta_machine_id: 5
    expect(Ip.all.taken.count).to eq 1

    ip_pool = IpPool.all.first!

    expect {
      ip_pool.destroy!
    }.to raise_exception ActiveRecord::RecordNotDestroyed

    expect(Ip.count).to eq 253
    expect(Ip.taken.count).to eq 1
  end

  it 'should not allow to create colliding pool' do
    IpPool.create! network: '10.0.1.2/24', gateway: '10.0.1.1'
    ip_pool = nil
    expect {
      ip_pool = IpPool.create! network: '10.0.1.222/25', gateway: '10.0.1.223'
    }.to raise_exception ActiveRecord::RecordNotUnique
    expect(IpPool.count).to eq 1

  end
end
