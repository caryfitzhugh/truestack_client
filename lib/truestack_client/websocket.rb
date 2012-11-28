require 'truestack_client/ws_cli'
module TruestackClient
  class Websocket
    def initialize(url, config)
      @config = config
      @key    = config.key
      log     = config.logger
      @url = URI.parse(url)
      @proto = :hybi07

      @ws_client = TruestackClient::WSClient.new(log, {:host => @url.host, :port => @url.port, :proto => @proto, :frame_compression => false})
      connect
    end

    def write_data(msg)
      @ws_client.write_data(JSON.generate(msg))
    end

    def method_missing(*args)
      name = args.shift
      @ws_client.send(name, *args)
    end

    def connect
      sec_headers = {}
      sec_headers["Truestack-Access-Key"] = @key
      sec_headers["Truestack-Client-Type"] = TruestackClient.create_type_string(@config.app_version)
      sec_headers["Truestack-Access-Environment"] = @config.app_environment

      @ws_client.connect([], sec_headers)
      sleep 1 # give it some time!
    end

    def connected?
      @ws_client.connected?
    end
  end
end
