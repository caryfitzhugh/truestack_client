module TruestackClient
  # The format is:  http://user_key@www.truestack.com/director_url
  class Configure

    def resource_uri=(v)
      @resource_uri = v
    end

    def logger=(l)
      @logger = l
    end

    def app_environment=(v)
      @app_environment = v
    end

    def app_environment
      @app_environment || 'default'
    end

    def app_version=(v)
      @app_version = v
    end

    def app_version
      @app_version || "Unknown"
    end

    def key
      URI(self.resource_uri).user
    end

    def host
      URI(self.resource_uri).host
    end

    def port
      URI(self.resource_uri).port
    end

    def director
      uri = URI(self.resource_uri)
      uri.user = ''
      uri
    end

    def logger
      if !@logger
        @logger = ::Rails.logger rescue Logger.new(STDOUT)
      end
      @logger
    end

    def set_resource_file_location(path)
      @resource_uri = nil
      @resource_file_path = path
      resource_uri
    end

    def resource_uri
      if !@resource_uri
        if File.exist?(@resource_file_path || "truestack_uri")
          @resource_uri = File.read(@resource_file_path || "truestack_uri") rescue ""
        else
          @resource_uri = ENV['TRUESTACK_URI']
        end
        if (@resource_uri == nil || @resource_uri == '')
          raise "Need to set env['TRUESTACK_URI'] or config/truestack_uri"
        end
        @resource_uri = @resource_uri.strip
      end
      @resource_uri
    end

  end
end
