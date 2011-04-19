############################################################################
#
# net_server.rb
#
# accept incoming TLS connections, parse and dispatch requests
#
############################################################################

require 'openssl'
require 'config'
require 'net_util'
require 'socket'
require 'net_server_client'
require 'thread'
require 'config_daemon'

module ProcessWanker
	
  ############################################################################
  #
  #
  #
  ############################################################################

	class TCPFilteredServer < TCPServer
		
		include Log
		
		def initialize(hostname,port,auth)
			@auth=auth
			super(hostname,port)
		end
		
		def accept()
			while(true)
				con=super()
        debug("got TCP connection from #{con.peeraddr.inspect}")
				return(con) if(validate_auth(con))
				ProcessWanker::with_logged_rescue("accept - reject remote addr") do
					con.close()
				end
			end
		end
		
		def validate_auth(con)

			remote_addr=con.peeraddr[3]
			remote_addr=IPAddr.new(remote_addr)
			
			if(!@auth.allow_ip(remote_addr))
				info("reject ip #{remote_addr.inspect}")
				return(false)
			end
			
			true
		end
		
	end

  ############################################################################
  #
  #
  #
  ############################################################################

	class NetServer
	
		include Log
	
		@@instance=nil	
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def initialize(cfg)
			
			@@instance=self
			@mutex=Mutex.new
			@clients=[]
			
			daemon=cfg.daemon
			auth=daemon.get_auth
			@auth=auth

			# check that we're not using default certs and listening anything other than
			# localhost.
			if(@auth.is_default)
				if(daemon.listen_hostname != ConfigDaemon::DEFAULT_LISTEN_HOSTNAME)
					
					error "***"
					error "*** For security reasons, I will only listen on #{ConfigDaemon::DEFAULT_LISTEN_HOSTNAME} while using"
					error "*** the default built-in SSL certificates. You must generate real"
					error "*** certificates if you wish to control this daemon remotely."
					error "***"
					
					daemon.listen_hostname=ConfigDaemon::DEFAULT_LISTEN_HOSTNAME
					
				end
			end
			
			@ca_cert=auth.ca_cert
			@context=OpenSSL::SSL::SSLContext.new
			@context.cert=auth.my_cert
			@context.key=auth.my_key
			@context.verify_mode=OpenSSL::SSL::VERIFY_PEER
			@context.verify_callback=proc do |preverify_ok,ssl_context|
				verify_peer(preverify_ok,ssl_context)
			end

#			@tcp_server=TCPServer.new(daemon.listen_hostname,daemon.listen_port)
			@tcp_server=TCPFilteredServer.new(daemon.listen_hostname,daemon.listen_port,auth)
			@ssl_server=OpenSSL::SSL::SSLServer.new(@tcp_server,@context)
			
			@server_thread=Thread.new { server_proc }
			
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def stop_server()
			@ssl_server.close
			@server_thread.join
			c=@clients.clone
			c.each do |c|
				c.disconnect()
			end
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def verify_peer(preverify_ok,ssl_context)
			if(!ssl_context.current_cert.verify(@ca_cert.public_key))
				info("client certificate rejected")
				return(false)
			end
			peer_name=ssl_context.current_cert.subject.to_a.select { |x| x[0]=="CN" }.map { |x| x[1] }[0]
			info("verified identity of #{peer_name}")

			if(@auth.accept_peers && !@auth.accept_peers[peer_name])
				info("failed to accept peer #{peer_name}")
				return(false)
			end
			if(@auth.reject_peers && @auth.reject_peers[peer_name])
				info("rejected peer #{peer_name}")
				return(false)
			end
			
			true
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def server_proc
			
			while(true)
				begin
					ssl_connection=@ssl_server.accept
				rescue OpenSSL::SSL::SSLError => e
					next
				rescue Errno::EBADF
					break
				end
				
				@mutex.synchronize do
					nc=NetServerClient.new(ssl_connection,self)
					info("new connection from #{nc.user}")
					@clients << nc
				end
			end
			info("server stopped")
			
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def client_closed(client)
			@mutex.synchronize do
				@clients.delete(client)
			end
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def post_fork()
			c=nil
			@mutex.synchronize do
				c=@clients.clone
			end
			c.each do |client|
				client.close_rudely()
			end
			ProcessWanker::with_logged_rescue("post_fork - stop_server") do
				stop_server()
			end
		end	
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def self.instance
			@@instance
		end	
	
	end

end
