require 'truestack_client/ws_cli'
module TruestackClient
  class Websocket
    def initialize(url, config)
      @config = config
      @key    = config.key
      log = config.logger
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
      sec_headers["TrueStack-Access-Key"] = @key

      @ws_client.connect([], sec_headers)
    end

    def connected?
      @ws_client.connected?
    end
  end
end
