############################################################################
#
# config_daemon_service.rb
#
# *_service {
# 	...
# }
#
############################################################################

require 'net_api'
require 'config_daemon_service_dependency'
require 'config'
require 'config_hook'

module ProcessWanker
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemonService < ConfigNode
		
		attr_accessor					:klass
		attr_accessor					:params
		attr_accessor					:name
		attr_accessor					:hooks

		def initialize(name,klass)
			@hooks=[]
			@name=name
			@klass=klass
			@params={}
		end
		
	end

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigDaemonServiceBuilder < Builder

		def hook(pattern,&block)
			@config.hooks << ConfigHook.new(@config,pattern,block)
		end
		
		def tags(*t)
			@config.params[:tags] ||= []
			@config.params[:tags] += t
		end
		
		def depends(name=nil, &block)
			@config.params[:dependencies] ||= []
			new_dependency = ConfigDaemonServiceDependencyBuilder.new.build(@config,[],block)
			new_dependency.service = name if (!name.nil? && new_dependency.service.nil?)
			@config.params[:dependencies] << new_dependency

		end
		
		def method_missing(method,*args,&block)
			if(block)
				@config.params[method] = block
			elsif(args.length == 0)
				@config.params[method] = true
			elsif(args.length == 1)
				@config.params[method] = args[0]
			else
				@config.params[method] = args
			end
		end
	
	
	end

	############################################################################
	#
	#
	#
	############################################################################


end
