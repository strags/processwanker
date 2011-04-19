#!/usr/bin/env ruby
############################################################################
#
# config_client_clusters.rb
#
# clusters {
#   auth {
#    ...
# 	}
# 	cluster("name") {
# 		...
# 	}
# }
#
#
#
############################################################################

require 'config_auth'
require 'config_client_cluster'
require 'config'

module ProcessWanker

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClientClusters < ConfigNode
		
		attr_accessor			:clusters
		attr_accessor			:auth
		
		def initialize()
			@clusters={}
		end
		
	end
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClientClustersBuilder < Builder
		
		def cluster(name,&block)
			cluster=Deferred.new(@config,[name],block,ConfigClientClusterBuilder)
			@config.clusters[name]=cluster
		end
		
		def auth(&block)
			@config.auth=Deferred.new(@config,[],block,ConfigAuthBuilder)
		end
		
	end

	
end
