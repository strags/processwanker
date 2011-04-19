############################################################################
#
# config_client.rb
#
# client {
#
#		auth {
#			...
# 	}
#
# 	clusters {
# 		cluster("name") {
# 			...
# 		}
# 	}
# }
#
#
#
############################################################################

require 'config_auth'
require 'config_client_clusters'
require 'config'

module ProcessWanker

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClient < ConfigNode
		
		attr_accessor			:auth
		attr_accessor			:clusters
		
		def get_cluster(name)
			
			@clusters ||= ConfigClientClusters.new
			
			if(name == "default" && !@clusters.clusters[name])
				@clusters.clusters[name]=Deferred.new(self,[name],proc {
					host("localhost") {
					}
				},ConfigClientClusterBuilder)
			end
			
			@clusters.clusters[name]
			
		end
		
	end
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClientBuilder < Builder
		
		def auth(&block)
			@config.auth=Deferred.new(@config,[],block,ConfigAuthBuilder)
		end
		
		def clusters(&block)
			@config.clusters=Deferred.new(@config,[],block,ConfigClientClustersBuilder)
		end

	end

	
end
