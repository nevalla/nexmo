require 'net/http'
require 'net/https'
require 'json'
require 'uri'

module Nexmo
  class Client
    def initialize(key, secret)
      @key, @secret = key, secret

      @headers = {'Content-Type' => 'application/x-www-form-urlencoded'}

      @http = Net::HTTP.new('rest.nexmo.com', 443)

      @http.use_ssl = true
    end

    attr_accessor :key, :secret, :http, :headers

    def send_message(data)
      response = @http.post('/sms/json', encode(data), headers)

      begin
        object = JSON.parse(response.body)['messages'].first
      rescue JSON::ParserError
        object = {'status' => '5', 'error-text' => 'Internal error'}
      end

      status = object['status'].to_i

      if status == 0
        Success.new(object['message-id'])
      else
        Failure.new(Error.new("#{object['error-text']} (status=#{status})"))
      end
    end

    private

    def encode(data)
      URI.encode_www_form data.merge(:username => @key, :password => @secret)
    end
  end

  class Success < Struct.new(:message_id)
    def success?
      true
    end

    def failure?
      false
    end
  end

  class Failure < Struct.new(:error)
    def success?
      false
    end

    def failure?
      true
    end
  end

  class Error < StandardError
  end
end
