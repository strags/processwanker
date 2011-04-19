#!/usr/bin/env ruby
############################################################################
#
# config_client_services.rb
#
# services("name") {
#   *_service {
#    ...
# 	}
# }
#
#
#
############################################################################

require 'config_auth'
require 'config_daemon_service'
require 'config'
require 'config_hook'

module ProcessWanker

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemonServices < ConfigNode
		
		attr_accessor			:services
		attr_accessor			:group_name
		attr_accessor			:hooks
		
		def initialize(group_name)
			@hooks=[]
			@group_name=group_name
			@services={}
		end
		
	end
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemonServicesBuilder < Builder

		def build(container,args,block)
			
			# create construction methods for various service classes
			ServiceMgr.instance.service_classes.each do |k,v|
				str="def #{k}(name,&block) ; "
				str << "@config.services[name] = ConfigDaemonServiceBuilder.new.build(@config,[name,#{v.name}],block) ; "
				str << "end"
				instance_eval(str)
			end
			
			super(container,args,block)
		end

		def hook(pattern,&block)
			@config.hooks << ConfigHook.new(@config,pattern,block)
		end
		

#		def build(args,block)
#			
#			# create construction methods for various service classes
#			ServiceMgr.instance.service_classes.each do |k,v|
#				str="def #{k}(name,&block) ; "
#				str << "@config.services << ConfigDaemonServiceBuilder.new.build(@config,[name],@default_group_name,#{v.name},block) ; "
#				str << "end"
#				instance_eval(str)
#			end
			
#			@config=ConfigDaemonServices.new(*args)
#			instance_eval(&block)
#			@config
#		end

		
	end

	
end

