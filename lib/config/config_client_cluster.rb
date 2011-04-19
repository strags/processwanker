############################################################################
#
# config_client_cluster.rb
#
# cluster {
# 	auth {
# 		...
# 	}
# 	host("name") {
# 		...
# 	}
# }
#
############################################################################

require 'config_client_host'
require 'config_auth'
require 'config'

module ProcessWanker
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClientCluster < ConfigNode
		
		attr_accessor					:name
		attr_accessor					:auth
		attr_accessor					:hosts
		
		def initialize(name)
			@name=name
			@hosts={}
		end
		
	end

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClientClusterBuilder < Builder
		
		def auth(&block)
			@config.auth=Deferred.new(@config,[],block,ConfigAuthBuilder)
		end

		def host(name,&block)
			@config.hosts[name]=Deferred.new(@config,[name],block,ConfigClientHostBuilder)
		end
	
	end

	############################################################################
	#
	#
	#
	############################################################################


end
