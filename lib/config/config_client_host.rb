############################################################################
#
# config_client_host.rb
#
# host("name") {
# 	auth {
# 		...
# 	}
# 	hostname		"hostname"
# 	port				port
# 	tag					"tag"
# }
# 
#
############################################################################

require 'config_auth'
require 'net_util'
require 'config'

module ProcessWanker
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClientHost < ConfigNode
		
		attr_accessor					:name
		attr_accessor					:hostname
		attr_accessor					:port
		attr_accessor					:tags
		attr_accessor					:auth
		
		def initialize(name)
			@name=name
			@hostname=name
			@tags={}
			@port=NetUtil::DEFAULT_PORT
		end
		
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
		def matches_spec(spec)
									
			# ensure it's in array form
			spec=spec.split(",")
			
			# check for inversion on first item
			if(spec.first[0..0]=="~")
				# insert implicit "all" at front
				spec=["all"] + spec
			end
			
			matches=false
			spec.each do |p|
				matches = matches_single(p,matches)
			end
			matches
						
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	  def matches_single(p,prev)
		
			if(p == "all")
				return(true)
			elsif(p[0..0] == "/")
				r=Regexp.new(p.split("/")[1])
				return(true) if(hostname =~ r)
				return(true) if(name =~ r)
			elsif(p[0..0] == "~")
				return(prev && !matches_single(p[1..-1],false))
			elsif(p[0..3] == "tag:")
				tag=p[4..-1]
	 			return(true) if(tags.include?(tag))
			elsif(p == name)
				return(true)
			elsif(p == hostname)
				return(true)
			end
			
			prev
		end
	
	end	
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigClientHostBuilder < Builder
		
		def build(container,args,block)
			super(container,args,block)
			@config.tags=@config.tags.keys.sort
			@config
		end
		
		def auth(&block)
			@config.auth=Deferred.new(@config,[],block,ConfigAuthBuilder)
		end

		def hostname(v)
			@config.hostname=v
		end

		def port(v)
			@config.port=v.to_i
		end
		
		def tags(*t)
			t.each do |v|
				@config.tags[v.to_s]=true
			end
		end
	
	end

	############################################################################
	#
	#
	#
	############################################################################

	############################################################################
	#
	#
	#
	############################################################################

	############################################################################
	#
	#
	#
	############################################################################


end
