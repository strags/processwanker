#!/usr/bin/env ruby
############################################################################
#
# config.rb
#
# base configuration loader
#
############################################################################

require 'config_node'
require 'config_client'
require 'config_daemon'
require 'config_auth'

module ProcessWanker

	############################################################################
	#
	# Configuration - the root configuration object
	#
	# client 		-		the client configuration section
	# daemon 		-		the daemon configuration section
	#
	############################################################################

	class Configuration < ConfigNode
		
		attr_accessor					:client
		attr_accessor					:daemon
		attr_accessor					:auth
		
		############################################################################
		#
		#
		#
		############################################################################

		def initialize()
			@client=nil
			@daemon=nil
		end
		
		def add_defaults()
			
			# ensure there's a default auth block
			if(!@auth)
				@auth = ConfigAuth.new()
				@auth.container=self
			end
			
			# ensure there's a default client config
			if(!@client)
				@client = ConfigClient.new
				@client.container=self
			end
			
		end
		
	end
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigurationBuilder < Builder
		
		def build(container,args,block)
			super(container,args,block)
			@config.add_defaults()
			@config
		end
		
		def client(&block)
			@config.client=Deferred.new(@config,[],block,ConfigClientBuilder)
		end

		def daemon(&block)
			@config.daemon=Deferred.new(@config,[],block,ConfigDaemonBuilder)
		end
		
		def auth(&block)
			@config.auth=Deferred.new(@config,[],block,ConfigAuthBuilder)
		end
		
	end

	############################################################################
	#
	#
	#
	############################################################################

	
end
