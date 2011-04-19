############################################################################
#
# util.rb
#
############################################################################

require 'log'

module ProcessWanker

	############################################################################
	#
	#
	#
	############################################################################
	
	def with_logged_rescue(context=nil,level=Log::ERROR)
		
		begin
			yield
		rescue Exception => e
			Log::log(context,level) if(context)
			Log::log(e.message,level)
			Log::log(e.backtrace.join("\n"),level)
		end
		
	end
	module_function			:with_logged_rescue


end
