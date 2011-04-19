############################################################################
#
# net_client.rb
#
# outgoing client connection
#
############################################################################

require 'openssl'
require 'config'
require 'config_client_cluster'
require 'config_client_host'
require 'config_client'
require 'config_auth'
require 'net_util'
require 'socket'
require 'net_connection'
require 'thread'

module ProcessWanker
	
  ############################################################################
  #
  #
  #
  ############################################################################

	class NetClient < NetConnection
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def initialize(cfg_host)
			
			@host=cfg_host
			@response=nil
			
			# find the real config...
#			auth=cfg_host.auth || cfg_host.parent.auth || cfg_host.parent.parent.auth
			auth=cfg_host.get_auth
			if(!auth)
				raise "could not find auth"
			end

			@ca_cert=auth.ca_cert
			@context=OpenSSL::SSL::SSLContext.new
			@context.cert=auth.my_cert
			@context.key=auth.my_key
			@context.verify_mode=OpenSSL::SSL::VERIFY_PEER
			@context.verify_callback=proc do |preverify_ok,ssl_context|
				verify_peer(preverify_ok,ssl_context)
			end
			
			@tcp_client=TCPSocket.new(cfg_host.hostname,cfg_host.port)
			ssl_connection=OpenSSL::SSL::SSLSocket.new(@tcp_client,@context)
			ssl_connection.connect
			super(ssl_connection)
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def verify_peer(preverify_ok,ssl_context)
			if(!ssl_context.current_cert.verify(@ca_cert.public_key))
				info("server certificate rejected")
				return(false)
			end
			true
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def on_msg(msg)
			super(msg)
			if(msg[:info])
				puts "==[#{@host.name}] #{msg[:info]}"
			end
			if(msg[:done])
				@response=msg
				disconnect()
			end
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def wait
			super
			@response
		end	
	
	end

end
