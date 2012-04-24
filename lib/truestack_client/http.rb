module TruestackClient
  class HTTP
    def initialize(config)
      @config = config
      @key  = config.key
      @url = @config.host
      @http = Net::HTTP.new(URI.parse(config.host))
      @http.open_timeout = 3 # in seconds
      @http.read_timeout = 3 # in seconds
    end
    def connected?
      true
    end

    def write_data(data)
      sec_headers = {}
      sec_headers["TrueStack-Access-Key"] = @key

      url = URI.parse(@config.host)
      type = data.delete(:type)
      request = Net::HTTP::Post.new("/app/#{type}")
      request.body = JSON.generate(data)
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
