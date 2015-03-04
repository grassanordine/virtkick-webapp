require 'net/http'

describe Wvm::Base do
  [Errno::EPIPE, Errno::ECONNRESET].each do |error|
    it "retries call on #{error}" do
      # given
      raise_error_on_first_call error
      # when
      response = Wvm::Base.call :post, '/'
      # then
      expect(response.to_hash).to eq({'key' => :val})
      expect(Wvm::Base).to have_received(:post).twice
    end
  end

  it 'reports error when no response or errors in json is present' do

    stub_request(:post, 'http://0.0.0.0:8000/').
        with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/x-www-form-urlencoded'}).
        to_return(:status => 200, :body => '{}', :headers => {})

    expect { Wvm::Base.call :post, '/'}.to raise_error Wvm::Base::BadRequest
  end

  def raise_error_on_first_call error
    thrown = false
    allow(Wvm::Base).to receive(:post) do
      if thrown
        request = OpenStruct.new({options: {}})
        body = OpenStruct.new({errors: [], response: {key: :val}})
        response = OpenStruct.new({ok?: true})
        HTTParty::Response.new request, response, lambda { body }
      else
        thrown = true
        raise error
      end
    end
  end

end
