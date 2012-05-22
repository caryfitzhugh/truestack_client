module TruestackClient
  class Configure
    attr_accessor :key, :host, :logger

    CONFIG_OPTIONS = {
      :host => "http://director.truestack.com",
      :key  => "ENTER_KEY",
      :browser_tracking => true,
      :code_paths => nil,
      :environments => :production,
      :logger_path  => 'log/truestack.log'
    }

    def example_config_file(opts={})
      opts = CONFIG_OPTIONS.merge(opts)
      opts.to_yaml
    end

    def logger
      if !@logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end
      @logger
    end
    def to_s
      "key: #{@key} host: #{@host}"
    end
  end
end
