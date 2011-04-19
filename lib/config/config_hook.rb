############################################################################
#
# config_hook.rb
#
# custom hooks
#
# hook("pattern") {
# 	...
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

	class ConfigHook < ConfigNode
		
		attr_accessor					:pattern
		attr_accessor					:block
		
		def initialize(container,pattern,block)
			@container=container
			@pattern=pattern
			@block=block
		end
		
	end


end

