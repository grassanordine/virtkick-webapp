describe 'Demo sessions' do
  before do
    SetupController.class_variable_set :@@ready, true
    Rails.configuration.x.demo_timeout = 5
    Mode.set 'demo'
  end

  after do
    SetupController.class_variable_set :@@ready, nil
  end

  it 'logs out after timeout' do
    post guests_path
    expect(response).to redirect_to machines_path

    get machines_path
    expect(response).to render_template :index

    Timecop.travel 5.minutes

    get machines_path
    expect(response).to redirect_to '/'
  end
end
