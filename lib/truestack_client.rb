require 'uri'
require 'base64'
require 'openssl'
require 'logger'
require 'truestack_client/ws_cli'

module TruestackClient
  class Client
    def initialize(url, opts={})
      @opts = opts
      @url = URI.parse(url)
      @proto = :hybi07

      log = opts[:logger] || Logger.new(STDOUT)
      log.log_level = opts[:logger_level] || Logger::INFO

      @client = WSClient.new(log, {:host => @url.host, :port => @url.port, :proto => @proto, :frame_compression => false})
    end

    def method_missing(*args)
      name = args.shift
      @client.send(name, *args)
    end

    def connect(opts={})
      opts = @opts.merge(opts)

      signature = AccessToken.create_signature(opts[:secret], opts[:nonce])

      sec_headers = {}
      sec_headers["TrueStack-Access-Key"] = opts[:key]
      sec_headers["TrueStack-Access-Token"]= signature
      sec_headers["TrueStack-Access-Nonce"]= opts[:nonce]

      @client.connect([opts[:protocol]], sec_headers)
    end

    def connected?
      @client.connected?
    end

    # Data should be a hash such as this:
    # {
    #   'grouping:function#name' => { s: start_time_since_request_began, d: duration_of_request }
    #   ...
    # }
    #
    # Where grouping is one of model / app / view / browser / custom
    # function name is either Class#action, or view_path
    #
    # timestamp is the time of the request occurring
    def request(action_name, data={}, timestamp= Time.now)
      @client.write_data({type: :request, :name=>action_name, :timestamp => timestamp, :data=>data}.to_json)
    end
  end
end
