module TruestackClient
  class Configure
    def key(v = nil)
      @key = key if v
      @key
    end
    def secret(v = nil)
      @secret = secret if v
      @secret
    end
    def host(v = nil)
      @host = host if v
      @host
    end
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
