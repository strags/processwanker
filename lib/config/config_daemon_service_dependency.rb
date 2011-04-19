############################################################################
#
# config_daemon_service_dependency.rb
#
# depends {
#   service		"spec"
#   up_for		5
# }
#
############################################################################

require 'net_api'
require 'config'

module ProcessWanker
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemonServiceDependency < ConfigNode
		
		attr_accessor					:service
		attr_accessor					:up_for

		def initialize()
			@up_for=3
		end
		
	end

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemonServiceDependencyBuilder < Builder

		def service(v)
			@config.service=v
		end
		
		def up_for(v)
			@config.up_for=v.to_i
		end
	
	end

	############################################################################
	#
	#
	#
	############################################################################


end
