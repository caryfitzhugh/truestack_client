if !defined? MyTimer
begin
  require 'system_timer'
  MyTimer = SystemTimer
rescue LoadError
  require 'timeout'
  MyTimer = Timeout
end
end

require 'socket'
require 'openssl'
require 'logger'
require File.join(File.dirname(__FILE__), 'ws_proto_hybi07')


class WSClient
  def initialize(logger, options)
    @logger = logger
    @host = options.delete(:host)
    @port = options.delete(:port)
    @timeout = options.delete(:timeout) || 40
    @version = options.delete(:proto) || :hybi07
    @secure = options[:secure] if options.has_key?(:secure)
    @proto = ProtoHybi07.new(@logger, options)
    @extensions = []

  end

  def connect(protocols=[], addl_headers=[])
    # make a handshake and send it to the server
    handshake = @proto.make_handshake(@host, protocols, @extensions, addl_headers)

    begin
      @logger.info "Writing handshake..."
      write_to_socket(handshake)
      @logger.info "Handshaking..."
      headers = read_http_headers
      @proto.check_handshake_response(headers)
      @logger.info "Handshake completed"
      # If the protocol does not match, we need to close connection
      if (@proto.valid_protocol_response?(headers, protocols))
        @logger.info "Protocols matched"
        true
      else
        @logger.info "No matching protocol"
        close(406, "No matching protocol")
        false
      end
    rescue IOError => e
      @logger.info "IO Error #{e}"
      return false
    rescue EOFError => e
      @logger.info "EOF Error #{e}"
      # They hung up on us
      return false
    end

  end

  def connected?
    @proto.connected
  end

  def close_received?
    @proto.close_received
  end

  def connect_raw(data)
    write_to_socket(data)
  end

  def read_raw
    @sock.read
  end

  def read_data
    @proto.read_data(@sock)
  end

  def write_data(data, frame_size=nil)
    @proto.send_text_data(@sock, data, frame_size)
  end

  def ping(text)
    @proto.ping(@sock, text)
  end

  def close(code=nil, message=nil)
    ret = @proto.close_connection(@sock, code, message)
    @sock.close
    return ret
  end

  private

  def read_http_headers
    headers = []
    begin
      line = @sock.readline.chomp
      headers << line if line.size > 0
    end while line != ""
    headers
  end

  def with_sock
    begin
      MyTimer.timeout(@timeout) do
        connect_i if @sock.nil?
        yield @sock
      end
    rescue Exception => e
      @sock.close if @sock
      @sock = nil
      return nil if e.is_a?(Timeout::Error)
      @logger.error("exception #{e.message}")
      return nil
    end
  end

  def connect_to(host, port, timeout=nil)
    @logger.debug("host #{host} port #{port}")

    if @secure
      sock = TCPSocket.new(host, port)
      ssl_context = OpenSSL::SSL::SSLContext.new()
#      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
      ssl_context.ca_file = File.join(File.dirname(__FILE__), "cacert.pem")
      sslsocket = OpenSSL::SSL::SSLSocket.new(sock, ssl_context)
      sslsocket.sync_close = true
      sslsocket.connect
      @old_socket = sock
      return sslsocket
    else
      addr = Socket.getaddrinfo(host, nil)

      sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

      if timeout
        secs   = Integer(timeout)
        usecs  = Integer((timeout - secs) * 1_000_000)
        optval = [secs, usecs].pack("l_2")
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
      end
      begin
        sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
      rescue Exception => e
        pp e
        raise
      end
      return sock
    end
  end

  def connect_i
    @sock = connect_to(@host, @port, @timeout == 0 ? nil : @timeout)
  end

  def read_from_socket
    @sock.read
  end

  def write_to_socket(cmd)
    begin
      connect_i if @sock.nil?
      MyTimer.timeout(2) do
        @sock.write(cmd)
      end
    rescue Exception => e
      @logger.error("exception #{e.message}")
      @sock.close if @sock
      if @old_socket
        @old_socket.close
        @old_socket = nil
      end
      @sock = nil
      return nil
    end
    return true
  end


end
