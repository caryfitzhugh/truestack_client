module TruestackClient
  class Configure
    attr_accessor :key, :host, :logger, :code

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
