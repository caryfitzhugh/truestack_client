module TruestackClient
  class HTTP
    def initialize(config)
      @config = config
    end
    def connected?
      true
    end

    def write_data(data)
      sec_headers = {}
      sec_headers["Truestack-Access-Key"] = @config.key

      type = data[:type]
      request = Net::HTTP::Post.new("/api/collector/#{type}")
      request.body = JSON.generate(data)
      request.initialize_http_header(sec_headers)

      res = Net::HTTP.new(@config.host, @config.port).start {|http| http.request(request) }
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        # OK
      else
        res.error!
      end
    end
  end
end
