############################################################################
#
# service.rb
#
# class representing a running service
#
############################################################################

require 'process_util'
require 'log'
require 'events'

module ProcessWanker

	class Service

		include Log

	  ############################################################################
	  #
	  # current state
	  #
	  ############################################################################

	  attr_accessor       :params
	  attr_accessor       :want_state
	  attr_accessor       :last_action_time
	  attr_accessor       :current_state
	  attr_accessor       :prev_state
	  attr_accessor       :last_transition_time
	  attr_accessor       :attempt_count
	  attr_accessor       :last_fail_time
	  attr_accessor       :show_state
	  attr_accessor				:dependencies
	  attr_accessor				:suppress
		attr_accessor				:ignore
		attr_accessor				:config_node
		attr_accessor				:want_state_mode
		attr_accessor				:stable

	  ############################################################################
	  #
	  # initialize
	  #
	  # iparams is a hash containing:
	  #
	  #  :name                	name of service (unique to this machine)
	  #
	  #  :tags												array of tags
	  #  :group_name                 	group name
	  #  :min_action_delay_secs				minimum delay between (automatic) actions
	  #  :start_grace_secs						delay between successive start attempts
	  #  :stop_grace_secs							delay between stop attempts
	  #  :stable_secs                	seconds the process must be in desired state to be considered stable
	  #  :fail_trigger_count         	number of transitions to trigger failing
	  #  :fail_suppress_secs         	seconds to delay actions after failing detected
	  #  :initial_state								(defaults to current state) :up or :down
		#  :watchdog_file               file to watch for mtime
		#  :watchdog_timeout_secs       restart service if watchdog_file hasn't been modified in this number of seconds
	  #
	  ############################################################################

		def initialize(iparams)

			# extract params
			extract_params(
				iparams,
				[
					:name,
					:tags,
					:group_name,
					:min_action_delay_secs,
					:start_grace_secs,
					:stop_grace_secs,
					:stable_secs,
					:fail_trigger_count,
					:fail_suppress_secs,
					:initial_state,
					:dependencies,
					:log_file,
					:watchdog_file,
					:watchdog_timeout_secs
				])

	    # warn about extra params
			iparams.keys.each do |k|
				warn "warning: ignoring unrecognized parameter: #{k.to_s}"
			end

	    # apply defaults
	    @params={
	      :min_action_delay_secs      =>    1,
	      :stable_secs                =>    20,
	      :fail_trigger_count         =>    5,
	      :fail_suppress_secs         =>    300,
	      :group_name									=>		"default",
	      :start_grace_secs						=>		5,
	      :stop_grace_secs						=>		5,
	      :dependencies								=>		[],
	    }.merge(@params)

			@params[:tags] ||= []

			# convert necessary things to symbols
			@params[:initial_state] = @params[:initial_state].to_sym if(@params[:initial_state])

	    # set state values
	    @last_action_time=Time.at(0)
	    @last_action=nil
	    @current_state=safe_do_ping()
	    @want_state=@params[:initial_state] || @current_state
	    @prev_state=safe_do_ping()
	    @last_transition_time=Time.at(0)
	    @attempt_count=0
	    @last_fail_time=Time.at(0)
	    @show_state=""
	    @suppress=false
			@want_state_mode=:boot
			@stable=false

	    # register with the manager
	    ServiceMgr::register_service(self)
	  end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def validate_params()
			raise "no name provided" if(!params[:name])
			@params.keys.each do |k|
				if(!keys.include?(k))
					warn "warning: unrecognized parameter #{k.to_s} ignored"
				end
			end
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def extract_params(params,keys)
			@params ||= {}
			keys.each do |k|
				@params[k]=params[k] if(params.has_key?(k))
				params.delete(k)
			end
		end

	  ############################################################################
	  #
	  # return the host-wide unique name of the service
	  #
	  ############################################################################

	  def name
	    @params[:name]
	  end

	  ############################################################################
	  #
	  # return the name of the group this process belongs to
	  #
	  ############################################################################

	  def group_name
	    @params[:group_name]
	  end

	  ############################################################################
	  #
	  # start the service. should not block for a considerable amount of time
	  #
	  ############################################################################

	  def do_start(attempt_ct)
	    raise "method not defined in base class"
	  end

	  ############################################################################
	  #
	  # stop the service - should not block for a considerable amount of time
	  #
	  ############################################################################

	  def do_stop(attempt_ct)
	    raise "method not defined in base class"
	  end

	  ############################################################################
	  #
	  # return state (:up, :down)
	  #
	  ############################################################################

	  def do_ping
	    raise "method not defined in base class"
	  end

	  ############################################################################
	  #
	  # resolve dependencies through name lookup
	  #
	  ############################################################################

	  def resolve_dependencies

	  	@dependencies=[]
	  	params[:dependencies].each do |dep|
				ServiceMgr::instance.match_services(dep.service).each do |k,v|
					@dependencies << { :service => v, :dep => dep }
				end
	  	end
	  end

	  ############################################################################
	  #
	  # safe, exception-catching methods
	  #
	  ############################################################################

		def safe_do(name)
			ProcessWanker::with_logged_rescue("#{name} - safe_do") do
				yield
			end
		end

		def safe_do_start(attempt_ct)
			safe_do("#{name}:do_start") { do_start(attempt_ct) }
		end

		def safe_do_stop(attempt_ct)
			safe_do("#{name}:do_start") { do_stop(attempt_ct) }
		end

		def safe_do_ping()
			p=:down
			safe_do("#{name}:do_start") { p=do_ping }
			p
		end

	  ############################################################################
	  #
	  # main logic
	  #
	  ############################################################################

	  def tick

	    #
	    # get current time
	    #

	    now=Time.now

	    #
	    # get current state, check for change, record transition time
	    #

	    state = safe_do_ping()
	    if(@current_state != state)
	      @prev_state = @current_state
	      @last_transition_time = now
	      @current_state = state
				@stable = false
        @show_state = state.to_s
	    end

	    #
	    # handle special :restart case
	    #

	    want=@want_state
	    if(want == :restart)
	      if(@current_state == :down)
	        want = :up
	        @want_state = :up
	        @last_action_time = Time.now
	      else
	        want = :down
	      end
	    end

			#
			# check dependencies
			#

			deps_ok=true
			@dependencies.each do |d|
				s=d[:service]
				if(s.current_state != :up)
					deps_ok=false
					next
				end
				tt=now - s.last_transition_time
				if(tt < d[:dep].up_for)
					deps_ok=false
				end
			end
			@suppress=(!deps_ok) && (@want_state != :down)
			if(@suppress)
				want = :down
			end

			#
			# have we been in the same state for a while?
			#

			stabilized=false
			elapsed = now - @last_transition_time
      if(!@stable && elapsed >= @params[:stable_secs])
				stabilized=true
				@stable=true
			end

			#
			# if we're up and stable, check watchdog timer
			#

			if(@stable && @current_state == :up && want == :up)
				if(@params[:watchdog_file] && @params[:watchdog_timeout_secs])
					timeout=true
					begin
						st = File.stat(@params[:watchdog_file])
						if((now - st.mtime) < @params[:watchdog_timeout_secs])
							timeout=false
						end
					rescue Exception => e
					end
					if(timeout)
						info("#{self.name}: watchdog file: #{@params[:watchdog_file]} has timed out")
						Event.dispatch("watchdog_timeout",self)
						@want_state = :restart
						want = :down
					end
				end
			end

	    #
	    # are we in the desired state?
	    #

	    if(@current_state == want)

				# did we just stabilize?
				if(stabilized)

	        @attempt_count = 0
	        @show_state = @current_state.to_s + " [stable]"

					# was this request part of a user request? if not, notify
					if(@want_state_mode == :none && want == :up)
						Event::dispatch("restarted",self)
					end

					# clear request mode
					@want_state_mode=:none
	      end

				# nothing more to do
	      return
	    end

			#
			# are we ignoring the process?
			#

			if(want == :ignore)
				@show_state = "#{@current_state.to_s} (ignored)"
				return
			end

	    #
	    # is it too soon to do anything?
	    #

			proposed_action = { :up => :start , :down => :stop }[want]
			return if(!check_action_delay(now,proposed_action))

	    #
	    # actually attempt to cause a change
	    #

			# update state
			@attempt_count=0 if(proposed_action != @last_action)
			@last_action=proposed_action
			@last_action_time=now

			# check for failing
      if(@attempt_count >= @params[:fail_trigger_count])
				info("#{self.name} has now had #{@attempt_count} attempts. considering it failed.")

        @show_state = "failing(#{proposed_action})"
        @last_fail_time = now
        @attempt_count = 0		# reset for next time

				Event::dispatch("fail-#{proposed_action.to_s}",self)

        return
      end

			# was this request part of a user request? if not, notify
			if(@want_state_mode == :none && proposed_action == :start && @attempt_count==0)
				Event::dispatch("restarting",self)
			end

      # do it
			@show_state = "#{proposed_action} [#{@attempt_count}]"
			if(proposed_action == :start)

				Event::dispatch("pre-launch",self)

				info("calling do_start for #{self.name}")
				safe_do_start(@attempt_count)

			else

				info("calling do_stop for #{self.name}")
				safe_do_stop(@attempt_count)

			end
      @attempt_count += 1

	  end

	  ############################################################################
	  #
	  # check the various timers, and see if we're allowed to take action
	  # on a specific service at this point...
	  #
	  ############################################################################

		def check_action_delay(now,proposed_action)

			elapsed=now - @last_action_time

			# check general-purpose between-action-delay
			return(false) if(elapsed < @params[:min_action_delay_secs])

			if(proposed_action == @last_action)

				# check grace periods
				return(false) if(@last_action == :start && elapsed < @params[:start_grace_secs])
				return(false) if(@last_action == :stop && elapsed < @params[:stop_grace_secs])

				# check failing suppression
				since_fail=now - @last_fail_time
				return(false) if(since_fail < @params[:fail_suppress_secs])
			end

			true
		end

	  ############################################################################
	  #
	  # set want state in response to a user request - clear all delay state,
	  # start with a clean slate.
	  #
	  ############################################################################

	  def set_want_state(state)
	  	@want_state = state
			@want_state_mode = :user
	  	@attempt_count = 0
	  	@last_action_time = Time.at(0)
	  	@last_fail_time = Time.at(0)
	  	if(@want_state != @current_state)
	  		@show_state = "received #{state.inspect}"
	  	end
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
				return(true) if(group_name =~ r)
				return(true) if(name =~ r)
			elsif(p[0..0] == "~")
				return(prev && !matches_single(p[1..-1],false))
			elsif(p[0..3] == "tag:")
				tag=p[4..-1]
 				return(true) if(params[:tags] && params[:tags].include?(tag))
			elsif(p == name)
				return(true)
			elsif(p == group_name)
				return(true)
			end

			prev
		end


	  ############################################################################
	  #
	  #
	  #
	  ############################################################################


	end

end
