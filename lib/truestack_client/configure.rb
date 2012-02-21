module TruestackClient
  class Configure
    attr_accessor :key, :secret, :host

    def logger(v = nil)
      if (v)
        @logger = v
      end
      if !@logger
        @logger = Logger.new(STDOUT)
        @logger.log_level = Logger::INFO
      end

      @logger
    end
    def log_level(v = nil)
      if (v)
        logger.log_level = v
      end
      logger.log_level
    end
  end
end
