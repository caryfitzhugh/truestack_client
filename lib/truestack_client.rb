require 'uri'
require 'base64'
require 'openssl'
require 'json'
require 'logger'
require 'net/http'
require 'truestack_client/websocket'
require 'truestack_client/http'
require 'truestack_client/configure'

module TruestackClient
  def self.configure
    yield self.config
    self.config
  end

  # Data should be a hash such as this:
  # {
  #   'grouping:function#name' => { s: start_time_since_request_began, d: duration_of_request }
  #   ...
  # }
  #
  # Where grouping is one of model / app / view / browser / custom
  # function name is either Class#action, or view_path
  #
  # timestamp is the time of the request occurring
  def self.request(action_name, start_time, method_data={})
      payload = JSON.generate({
                                    :type => :request,
                                    :name=>action_name,
                                    :timestamp => start_time,
                                    :data=>method_data
                                   })
      binding.pry
      websocket_or_http.write_data(payload)
  end

  def self.exception(action_name, e)
      websocket_or_http.write_data(JSON.generate({
                                    :type => :exception,
                                    :name=>action_name,
                                    :timestamp => start_time,
                                    :data=>{:type => e.type, :backtrace => e.backtrace, :to_s => e.to_s  }
                                   }))
  end

  def self.deploy(commit_id, commit_data={})
    http.deploy(JSON.generate({:commit_id => commit_id, :data => commit_data}))
  end

  def self.http
    TruestackClient::HTTP.new
  end

  def self.websocket_or_http
    if @websocket && @websocket.connected?
      @websocket
    else
      Rails.logger.info "Config -- " + config.to_s
      uri = URI(config.host)
      uri.path = "/director"
      res = Net::HTTP.get_response(uri)
      # TODO Add some kind of limiting here
      self.logger.info "Response from director: #{res}"

      if (res.code === '307')
        @websocket = TruestackClient::Websocket.new(res['location'], config)
      else
        # Are we leaving this open / tossing resources?
        @websocket = nil
        TruestackClient.http
      end
   end
  end

  def self.logger
    config.logger
  end
  def self.config
    @config ||= TruestackClient::Configure.new
  end
  def self.create_signature(secret, nonce)
    digest = OpenSSL::Digest::Digest.new('sha256')
    OpenSSL::HMAC.hexdigest(digest, secret, nonce)
  end
  def self.create_nonce
    Time.now.to_i.to_s + OpenSSL::Random.random_bytes(32).unpack("H*")[0]
  end
end
