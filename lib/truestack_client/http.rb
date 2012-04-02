module TruestackClient
  class HTTP
    def initialize(config)
      @config = config
      @key  = config.key
      @secret = config.secret
      @url = @config.host
      @http = Net::HTTP.new(URI.parse(config.host))
      @http.open_timeout = 3 # in seconds
      @http.read_timeout = 3 # in seconds
    end
    def connected?
      true
    end
    def deploy(data)
      nonce = TruestackClient.create_nonce
      signature = TruestackClient.create_signature(@secret, nonce)

      sec_headers = {}
      sec_headers["TrueStack-Access-Key"] = @key
      sec_headers["TrueStack-Access-Token"]= signature
      sec_headers["TrueStack-Access-Nonce"]= nonce

      request = Net::HTTP::Post.new("/app/deployments")
      request.body = data
      request.initialize_http_header(sec_headers)
      http.request(request)
    end
    def write_data(data)
      nonce = TruestackClient.create_nonce
      signature = TruestackClient.create_signature(@secret, nonce)

      sec_headers = {}
      sec_headers["TrueStack-Access-Key"] = @key
      sec_headers["TrueStack-Access-Token"]= signature
      sec_headers["TrueStack-Access-Nonce"]= nonce


      url = URI.parse(@config.host)
      request = Net::HTTP::Post.new("/app/event")
      request.body = data
      request.initialize_http_header(sec_headers)

      res = Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        # OK
      else
        res.error!
      end
    end
  end
end
