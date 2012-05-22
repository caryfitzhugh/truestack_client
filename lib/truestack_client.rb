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

  def self.reset
    if @websocket
      @websocket.close
      @websocket = nil
    end
  end

  # Data should be a hash such as this:
  #
  #
  #  request:
  #    name: controller#action
  #    actions: {
  #      name: klass#method
  #      [{
  #           tstart
  #           tend
  #      },...]
  #    ]
  #
  # Where grouping is one of model / controller / view / browser / helper / ?
  # function name is either Class#action, or view_path (starting with app/...)
  #
  # tstart is just a ruby DateTime, tend as well.
  def self.request(action_name, actions={})
      payload = {
                  :type => :request,
                  :name=> action_name,
                  :actions=>actions
                }

      # Convert to tstart timestamps
      actions.each_pair do |name, calls|
        actions[name] = calls.map do |call|
          call.merge({:tstart => self.to_timestamp(call[:tstart]),
                      :tend   => self.to_timestamp(call[:tend])})
        end
      end

      TruestackClient.logger.info "Pushing request data: " + payload.to_yaml
      retry_if_failed_connection do
        websocket_or_http.write_data payload
      end
  end

  def self.exception(action_name, start_time, failed_in_method, actions, e, request_env)
      request_env_data = {}

      request_env.each_pair do |k, v|
        begin
        request_env_data[k.to_s] = v.to_s
        rescue Exception => e
        end
      end

      payload = {
                      :type => :exception,
                      :request_name=>action_name,
                      :failed_in_method  => failed_in_method,
                      :actions           => actions,
                      :tstart            => self.to_timestamp(start_time),
                      :exception_name    => e.to_s,
                      :backtrace         => e.backtrace,
                      :env => request_env_data
                     }

      TruestackClient.logger.info "Pushing exception data: " + payload.to_yaml

      retry_if_failed_connection do
        websocket_or_http.write_data payload
      end
  end

  def self.startup(commit_id, host_id, instrumented_method_names)
    payload = {
        :type      => :startup,
        :host_id   => host_id,
        :commit_id => commit_id,
        :tstart    => self.to_timestamp(Time.now),
        :methods   => instrumented_method_names
    }

    TruestackClient.logger.info "Pushing startup data: " + payload.to_yaml
    retry_if_failed_connection do
      websocket_or_http.write_data payload
    end
  end

  def self.http
    TruestackClient::HTTP.new(config)
  end

  def self.websocket_or_http
    if @websocket && @websocket.connected?
      @websocket
    else
      Rails.logger.info "Config -- " + config.to_s
      uri = config.director
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

  def self.to_timestamp(time)
    if (time.class != Fixnum)
      (time.to_f.*1000).to_i
    else
      time
    end
  end

  def self.retry_if_failed_connection
    tries = 0
    begin
      tries += 1
      yield
    rescue Exception => e
      self.logger.info "Exception: #{e}"
      if tries <= 1
        self.reset
        retry
      end
    end
  end
end
