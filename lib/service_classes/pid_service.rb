############################################################################
#
# process_service.rb
#
# class representing a service that is a command-line launchable process
#
############################################################################

require 'service'
require 'digest/md5'
require 'etc'
require 'process_service'
require 'process_util'

module ProcessWanker
	
	class PIDService < ProcessService

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def self.nice_name
			"pid_service"
		end

	  ############################################################################
	  #
	  # iparams is a hash containing:
	  #
	  #   :start_cmd
		#   :pid_file
	  #   :start_dir (optional)
	  #   :run_user (optional)
	  #   :soft_kill_limit (optional)
	  #
	  # plus anything to be passed to Service
	  #
	  ############################################################################
	
	  def initialize(iparams)
	  
			# extract parameters
			extract_params(
				iparams,
				[
					:pid_file,
				])
	
			raise "service has no pid_file" if(!@params[:pid_file])

	    super(iparams)    
	  end

	  ############################################################################
	  #
	  # stop
	  #
	  # stop the process (either with -TERM or -KILL)
	  #
	  ############################################################################
	  
	  def do_stop(attempt_count)
	    info("do_stop[#{attempt_count}] for #{self.name}")
	  
	  	kl=@params[:soft_kill_limit]
	  	mode = (kl && attempt_count >= kl) ? :hard : :soft

			if(mode == :soft)
				if(params[:stop_cmd])
					system(params[:stop_cmd])
					return
				end
			end	    
	    
			ProcessWanker::with_logged_rescue("PidServer::do_stop - reading pid file") do
				pid = File.read(@params[:pid_file]).strip.to_i
				Process.kill({ :hard => "KILL", :soft => "TERM" }[mode],pid)
			end
			
	  end
	  
	  ############################################################################
	  #
	  # ping
	  #
	  # return run state of process
	  #
	  ############################################################################
	  
	  def do_ping
			begin
				pid = File.read(@params[:pid_file]).strip.to_i
				return(:up) if(ProcessUtil::all_processes[pid])
			rescue Exception => e
			end
			:down
	  end

	  ############################################################################
	  #
	  # override the env_hash() method, to prevent our services being tagged
		# in the same way process_services are.
	  #
	  ############################################################################
	  
		def env_hash()
			nil
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
	end


	ServiceMgr::register_service_class(PIDService)

end


