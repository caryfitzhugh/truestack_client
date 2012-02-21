module TruestackClient
  class Configure
    attr_accessor :key, :secret, :host

    def logger(v = nil)
      if (v)
        @logger = v
      end
      @logger ||= Logger.new(STDOUT)
      log_level # To set default
      @logger
    end
    def log_level(v = nil)
      if (v)
        logger.log_level = v
      else
        logger.log_level = Logger::INFO
      end
      logger.log_level
    end
  end
end
