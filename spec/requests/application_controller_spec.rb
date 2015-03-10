describe 'Demo sessions' do
  before do
    Hypervisor.bootstrap
    SetupController.class_variable_set :@@ready, true
    Rails.configuration.x.demo_timeout = 5
    Mode.set 'demo'
  end

  after do
    SetupController.class_variable_set :@@ready, nil
  end

  it 'logs out after timeout' do
    post guests_path
    expect(response).to redirect_to '/machines'

    stub_request(:get, "http://0.0.0.0:8000/1/storages").
        with(:headers => {:'Accept'=>'application/json'}).
        to_return(
            status: 200,
            body: '{"errors": [], "response": {"secrets": [], "storages": [{"status": 1, "name": "virtkick-iso", "enabled": true, "volumes": 12, "type": "dir", "size": 264086360064}, {"status": 1, "name": "virtkick-hdd", "enabled": true, "volumes": 288, "type": "dir", "size": 264086360064}]}}',
            headers: {
              :'content-type' => 'application/json; charset=utf-8'
            }
        )

    get '/machines'
    expect(response).to render_template :home

    Timecop.travel 5.minutes

    get machines_path
    expect(response).to redirect_to '/'
  end
end
