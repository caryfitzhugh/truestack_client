module TruestackClient
  class Websocket
    def initialize(url, config)
      @config = config
      @key  = config.key
      @secret = config.secret
      log = config.logger
      @url = URI.parse(url)
      @proto = :hybi07

      @ws_client = WSClient.new(log, {:host => @url.host, :port => @url.port, :proto => @proto, :frame_compression => false})
      @ws_client.connect
    end

    def method_missing(*args)
      name = args.shift
      @ws_client.send(name, *args)
    end

    def connect
      nonce = TruestackClient.create_nonce
      signature = TruestackClient.create_signature(@secret, nonce)

      sec_headers = {}
      sec_headers["TrueStack-Access-Key"] = @key
      sec_headers["TrueStack-Access-Token"]= signature
      sec_headers["TrueStack-Access-Nonce"]= nonce

      @ws_client.connect([], sec_headers)
    end

    def connected?
      @ws_client.connected?
    end
  end
end
