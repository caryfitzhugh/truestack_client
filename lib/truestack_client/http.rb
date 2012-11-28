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
      sec_headers["Truestack-Client-Type"] = TruestackClient.create_type_string(@config.app_version)
      sec_headers["Truestack-Access-Environment"] = @config.app_environment

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
