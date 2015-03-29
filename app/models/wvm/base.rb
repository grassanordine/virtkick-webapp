require 'httparty'
require 'recursive_open_struct'
require 'app/models/hypervisor'

class Wvm::Base

  class BadRequest < StandardError
  end

  include ActiveModel::Model
  include ActiveModel::Validations

  include HTTParty
  base_uri 'http://0.0.0.0:8000/'
  default_timeout 20

  def as_json config = {}
    self.instance_values.as_json config
  end

  def self.call method, url, **body
    params = {headers: {'Accept' => 'application/json'}}
    if method == :post
      if body[:json]
        params[:headers]['Content-Type'] = 'application/json'
        params[:body] = body[:json].to_json
      else
        params[:headers]['Content-Type'] = 'application/x-www-form-urlencoded'
        params[:body] = body
      end

    end

    response = try_twice { send method, url, params }
    unless response.response.ok?
      raise Errors, ['Backend responded with 500 Internal Server Error']
    end

    unless response.parsed_response['errors'] or response.parsed_response['response']
      raise BadRequest.new('response does not have "errors" or "response"')
    end

    errors = response.parsed_response['errors']
    if errors and errors.size > 0
      raise Errors, errors
    end

    response = response.parsed_response['response'] || {}
    HashWithIndifferentAccess.new(response.to_hash)
  end

  def self.hypervisor hypervisor_id

    hypervisor = Hypervisor.find_by_id hypervisor_id

    unless hypervisor
      raise Exception.new('No hypervisor found')
    end
    hypervisor
  end

  private
  def self.try_twice
    yield
  rescue Errno::EPIPE, Errno::ECONNRESET
    yield
  end
end
