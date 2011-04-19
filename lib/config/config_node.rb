#!/usr/bin/env ruby
############################################################################
#
# config_node.rb
#
# config helper stuff
#
############################################################################

module ProcessWanker

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigNode
		attr_accessor					:container

		############################################################################
		#
		# find_attributes
		#
		# walk from the current object up to the root, looking for the named attribute
		#
		############################################################################
		
		def find_attributes(name)
			r=[]
			p=self
			while(p)
				if(p.respond_to?(name))
					v=p.send(name)
					r << v if(v)
				end
				break if(!p.respond_to?("container"))
				p=p.container
			end
			r
		end

		# find the innermost auth block
		def get_auth()
			find_attributes("auth").first
		end
		
	end

	############################################################################
	#
	# Deferred
	#
	# there are situations where we don't wish to evaluate all of the
	# configuration unless necessary - for instance, we don't want the daemon
	# to evaluate the list of clusters in the client configuration (particularly
	# if it involves querying the cloud).
	#
	# so, we wrap blocks in Deferred objects which are transparently evaluated
	# on-demand.
	#
	############################################################################

	class Deferred
		
		def initialize(deferred_container,deferred_args,deferred_block,deferred_builder)
			@deferred_container=deferred_container
			@deferred_args=deferred_args
			@deferred_block=deferred_block
			@deferred_builder=deferred_builder
			@deferred_object=nil
		end
		
		def method_missing(name,*args)
			if(!@deferred_object)
				@deferred_object=@deferred_builder.new.build(
					@deferred_container,
					@deferred_args,
					@deferred_block)
			end
			@deferred_object.send(name,*args)
		end
		
	end
	
	############################################################################
	#
	#
	#
	############################################################################

	class Builder

		def build(container,args,block)
			@config=klass.new(*args)
			@config.container=container
			instance_eval(&block)
			@config
		end
		
		def klass
			cn=self.class.name
			cn.gsub!("Builder","")
			cn=cn.split("::")[-1]
			ProcessWanker::const_get(cn)
		end
		
	end
	
	############################################################################
	#
	#
	#
	############################################################################

	module Config

		@@config_path=ENV["PW_CFG"] || "/etc/pw/pw.cfg"
	
		def get_config_path()
			@@config_path
		end
		module_function			:get_config_path
	
		def set_config_path(path)
			@@config_path=path
		end
		module_function			:set_config_path
		
		def load_config(path)
			ProcessWanker::loaded_config=nil
			load(path)
			ProcessWanker::loaded_config
		end
		module_function			:load_config
		
	end
	

	############################################################################
	#
	#
	#
	############################################################################

	attr_accessor					:loaded_config
	module_function				:loaded_config
	module_function				:loaded_config=

	def config(&block)
		@loaded_config=ConfigurationBuilder.new.build(nil,[],block)
	end
	module_function			:config
	
	
end
