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
  #
  #
  #  request:
  #    name: controller#action
  #    request_id:  (unique token)
  #    actions: [
  #      {    type => controller | model | helper | view | browser | lib
  #           tstart
  #           tend
  #           duration
  #           name: klass#method
  #      }
  #    ]
  #
  # Where grouping is one of model / controller / view / browser / helper / ?
  # function name is either Class#action, or view_path (starting with app/...)
  #
  # tstart is just a ruby DateTime
  def self.request(action_name, request_id, actions={})
      payload = JSON.generate({
                      :type => :request,
                      :name=> action_name,
                      :request_id => request_id,
                      :actions=>actions
                     })
      TruestackClient.logger.info "Pushing request data: " + payload
      websocket_or_http.write_data(payload)
  end

  def self.exception(action_name, start_time, e, request_env)
      request_env_data = {}
      request_env.each_pair do |k, v|
        begin
        request_env_data[k.to_s] = v.to_s
        rescue Exception => e
        end
      end

      payload = (JSON.generate({
                      :type => :exception,
                      :request_name=>action_name,
                      :tstart => start_time,
                      :exception_name => e.to_s,
                      :backtrace => e.backtrace,
                      :env => request_env_data
                     }))
      TruestackClient.logger.info "Pushing exception data: " + payload
      websocket_or_http.write_data payload
  end

  def self.deploy(commit_id, commit_data={})
    http.deploy(JSON.generate({:commit_id => commit_id, :data => commit_data}))
  end

  def self.http
    TruestackClient::HTTP.new(config)
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
end
