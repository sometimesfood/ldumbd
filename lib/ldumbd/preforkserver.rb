require 'socket'
require 'etc'

module Ldumbd
  class PreforkServer
    def initialize(opt)
      @acceptor = nil
      @bind_address = opt[:bindaddr] || '0.0.0.0'
      @port = opt[:port] || 1389
      @group = opt[:group]
      @user = opt[:user]
      @nodelay = opt.has_key?(:nodelay) ? opt[:nodelay] : true
      @listen = opt[:listen] || 10
      @num_processes = opt[:num_processes] || 10
      @debug = opt[:debug]
    end

    def run(&block)
      start
      Process::GID.change_privilege(Etc.getgrnam(@group)) if @group
      Process::UID.change_privilege(Etc.getpwnam(@user)) if @user
      @num_processes.times do
        fork do
          trap('INT') { exit }

          puts "child #$$ accepting connections on #{@bind_address}:#{@port}" if @debug
          loop do
            socket = @acceptor.accept
            block.call(socket)
            socket.close
          end
          exit
        end
      end
      self
    end

    def join
      Process.waitall
    end

    private
    def start
      @acceptor = TCPServer.new(@bind_address, @port)
      if @nodelay
        @acceptor.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      end
      @acceptor.listen(@listen)
      trap('EXIT') { @acceptor.close }
    end
  end
end

module LDAP
  class Server
    def run_preforkserver
      opt = @opt
      server = Ldumbd::PreforkServer.new(opt)
      @thread = server.run do |socket|
        LDAP::Server::Connection::new(socket, opt).handle_requests
      end
    end
  end
end
