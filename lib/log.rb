############################################################################
#
# log.rb
#
############################################################################

require 'thread'

module ProcessWanker

	############################################################################
	#
	#
	#
	############################################################################
	
	module Log
	
		@@mutex=Mutex.new	

		############################################################################
		#
		#
		#
		############################################################################
		
		DEBUG			=			0	
		INFO			=			1
		WARN			=			2
		ERROR			=			3

		@@level=INFO

		############################################################################
		#
		#
		#
		############################################################################
		
		def set_level(level)
			@@level=level
		end		
		module_function			:set_level

		############################################################################
		#
		#
		#
		############################################################################
		
		def log(msg,level=INFO)
			return unless(level >= @@level)
			@@mutex.synchronize do
				STDOUT.puts "[#{level}] [#{Time.new}] #{msg}"
        STDOUT.flush
			end
		end
		module_function		:log	
	
		############################################################################
		#
		#
		#
		############################################################################
		
		def error(msg)
			log(msg,ERROR)
		end	
		module_function		:error
		def warn(msg)
			log(msg,WARN)
		end	
		module_function		:warn
		def info(msg)
			log(msg,INFO)
		end
		module_function		:info
		def debug(msg)
			log(msg,DEBUG)
		end
		module_function		:debug

	end


	include Log

end
