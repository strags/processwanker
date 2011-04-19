############################################################################
#
# config_smtp.rb
#
# smtp block parser:
#
# smtp {
#   server					"smtp.mymailprovider.com"
# 	port						25
#   secure					"starttls"   ("ssl")
#   to_addr					"joe-admin@foobar.com"
# 	from_addr				"pw@mydomain.com"
# 	userid					"fred"
#   password 				"mypass123"
#   auth_method			"plain"			("login", "cram_md5")
# }
#
############################################################################

require 'ipaddr'
require 'openssl'
require 'config'

module ProcessWanker
	
	############################################################################
	#
	#
	#
	############################################################################

	class ConfigSMTP < ConfigNode
		
		attr_accessor					:server
		attr_accessor					:port
		attr_accessor					:secure
		attr_accessor					:to_addrs
		attr_accessor					:from_addr
		attr_accessor					:userid
		attr_accessor					:password
		attr_accessor					:auth_method
		
		def initialize()
			@to_addrs=[]
			port=25
			ssl=false
			from_domain=`hostname`.strip
		end
		
	end

	############################################################################
	#
	#
	#
	############################################################################

	class ConfigSMTPBuilder < Builder
				
		def server(v)
			@config.server=v
		end
				
		def port(v)
			@config.port=v.to_i
		end
				
		def secure(v)
			v=v.to_sym
			raise "bad smtp secure setting" if(![:ssl,:starttls,:tls].include?(v))
			@config.secure=v
		end
				
		def from_addr(v)
			@config.from_addr=v
		end
		
		def to_addrs(*v)
			@config.to_addrs += v
		end
		
		def userid(v)
			@config.userid=v
		end
		
		def password(v)
			@config.password=v
		end
		
		def auth_method(v)
			@config.auth_method=v.to_sym
		end
	
	end

	############################################################################
	#
	#
	#
	############################################################################

end

