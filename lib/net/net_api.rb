############################################################################
#
# net_api.rb
#
# utilities for constructing and executing network requests
#
############################################################################

require 'log'
require 'util'

module ProcessWanker
	
	module NetApi
	
		include Log
	
	  ############################################################################
	  #
	  # a Net request is a hash that has a :cmd field, and a bunch of other parameters.
	  #
	  # :cmd can be
	  #
	  #   -		:start [spec]
	  #		-		:restart [spec]
	  #		-		:stop [spec]
	  #		-		:list [spec]
	  #
	  # other args:
	  #
	  # :spec           -   spec to match processes against
	  #
	  #	:sequential			-		if present, execute each service operation sequentially,
	  #                     rather than in parallel - and delay :sequential seconds
	  #                     between each service.
	  #                      
	  # :wait						-		if present max# of secs to wait for each process to reach
	  #                     desired state.
	  #
	  ############################################################################

	  ############################################################################
	  #
	  # execute a command from a remote client. called from the client's
	  # read thread.
	  #
	  ############################################################################

		def execute(cmd,connection)

			Log::info("received command #{cmd.inspect} from #{connection.user}")

			# execute
			if(cmd[:cmd] == :reload)
			
				ServiceMgr.instance.reload_config=true
				
				# wait for service manager to tick
				ticks=ServiceMgr.instance.tick_count
				sleep(0.5) while(ServiceMgr.instance.tick_count-ticks < 2)
			
			elsif(cmd[:cmd] == :debug)
				
				cls={}
				GC.start
				ObjectSpace.each_object do |o|
					cls[o.class.name] ||= 0
					cls[o.class.name] += 1
				end
				return({ :counts => cls })
				
			elsif(cmd[:cmd] == :terminate)
			
				ServiceMgr.instance.terminate=true
				connection.inform("terminating")
				return(nil)
			
			elsif([:stop,:restart,:start,:ignore].include?(cmd[:cmd]))
				
				# get hash of services		
				services=ServiceMgr::instance.match_services(cmd[:spec] || "all")
	
				threads=[]
				services.keys.sort.each do |sn|
				
					service=services[sn]
					
					if(cmd[:sequential])
						execute_cmd_single(cmd,service,connection)
						sleep(cmd[:sequential])
					else
						threads << Thread.new do 
							ProcessWanker::with_logged_rescue("execute_cmd_single") do
								execute_cmd_single(cmd,service,connection)
							end
						end
					end				
					
				end
				
				threads.each { |t| t.join }

			end
			
			# construct response
			services ||= ServiceMgr::instance.match_services(cmd[:spec] || "all")
	
			resp={ :services => {} }
			services.keys.sort.each do |sn|
				service=services[sn]
				resp[:services][sn] =
				{
					:name				=>		service.name,
					:group_name	=>		service.group_name,
					:tags				=>		service.params[:tags],
					:want_state	=>		service.want_state,
					:show_state	=>		service.show_state,
					:suppress		=>		service.suppress
				}
			end
			resp
		end
		
		module_function			:execute
	
	  ############################################################################
	  #
	  # execute a command from a remote client. called from the client's
	  # read thread.
	  #
	  ############################################################################
	
		def execute_cmd_single(cmd,service,connection)

			connection.inform("send #{cmd[:cmd].inspect} to #{service.name}")

			want={
				:start		=>	:up,
				:stop			=>	:down,
				:restart	=>	:restart,
				:ignore		=>	:ignore
			}[cmd[:cmd]]
			if(want)
				Log::debug("sending #{want} to #{service.name}")
				service.set_want_state(want)
			end
			
			wait=cmd[:wait]
			return(false) if(!wait)
			start_time=Time.now
			
			# wait for service manager to tick at least once
			ticks=ServiceMgr.instance.tick_count
			sleep(0.5) while(ServiceMgr.instance.tick_count == ticks)

			return(true) if(want == :ignore)
			

			# wait for process to be in desired state
			while(service.current_state != service.want_state || service.want_state == :restart)
				sleep(0.5)
				
				# timeout?
				if((Time.now - start_time) >= wait)
					connection.inform("timed out waiting for #{service.name}")
					return(false)
				end
			end
			
			true
		end	
	
		module_function			:execute_cmd_single
	
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

end
