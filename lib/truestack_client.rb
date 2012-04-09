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
