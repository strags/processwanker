############################################################################
#
# config_daemon.rb
#
# daemon {
# 	listen_hostname			"0.0.0.0"
# 	listen_port					45231
#   log_file						"filename"
# 	auth {
# 		...
# 	}
#   services("group-name") {
# 		...
#   }
# }
#
############################################################################

require 'config_auth'
require 'config_smtp'
require 'config_daemon_services'
require 'config'
require 'config_hook'

module ProcessWanker

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemon < ConfigNode
		
		DEFAULT_LISTEN_HOSTNAME="127.0.0.1"
		
		attr_accessor					:services	
		attr_accessor					:auth
		attr_accessor					:smtp
		attr_accessor					:hooks
		attr_accessor					:listen_hostname
		attr_accessor					:listen_port
		attr_accessor					:log_file
		
		def initialize()
			@hooks=[]
			@services={}
			@listen_hostname=DEFAULT_LISTEN_HOSTNAME
			@listen_port=NetUtil::DEFAULT_PORT
		end
		
		
	end
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemonBuilder < Builder
		
		def auth(&block)
			@config.auth=Deferred.new(@config,[],block,ConfigAuthBuilder)
		end
		
		def hook(pattern,&block)
			@config.hooks << ConfigHook.new(@config,pattern,block)
		end
		
		def smtp(&block)
			@config.smtp=Deferred.new(@config,[],block,ConfigSMTPBuilder)
		end
		
		def listen_hostname(v)
			@config.listen_hostname=v
		end
		
		def listen_port(v)
			@config.listen_port=v.to_i
		end
		
		def log_file(v)
			@config.log_file=v
		end
		
		def services(name="default",&block)
			@config.services[name]=Deferred.new(@config,[name],block,ConfigDaemonServicesBuilder)
		end

	end

	
end
