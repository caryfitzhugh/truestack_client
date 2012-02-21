module TruestackClient
  class Configure
    attr_accessor :key, :secret, :host

    def logger(v = nil)
      if (v)
        @logger = v
      end
      if !@logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end
      @logger
    end
  end
end
