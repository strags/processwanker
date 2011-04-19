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
require 'net_util'

module ProcessWanker
	
	class ProcessService < Service

		include Log

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def self.nice_name
			"process_service"
		end

	  ############################################################################
	  #
	  # iparams is a hash containing:
	  #
	  #   :start_cmd
	  #   :start_dir (optional)
	  #   :stop_cmd (optional)
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
					:start_cmd,
					:start_dir,
					:stop_cmd,
					:run_user,
					:soft_kill_limit,
				])
	
			# set defaults
	  	@params=
	  	{
	  		:soft_kill_limit		=>		3,
	  		:start_dir 					=> 		"/"
	  	}.merge(@params)

			raise "service has no start_cmd" if(!@params[:start_cmd])

			# determine run_user properties
			if(@params[:run_user])
				if(@params[:run_user].class == String)
					@params[:run_user]=Etc.getpwnam(@params[:run_user])
				elsif(@params[:run_user].class == Fixnum)
					@params[:run_user]=Etc.getpwuid(@params[:run_user].to_i)
				else
					raise "bad run_user parameter for process_service"
				end

				# verify we can switch to this uid if necessary
				current_uid=Process.euid()
				if(current_uid != 0 && current_uid != @params[:run_user].uid)
					raise "can't have a :run_user parameter unless we are running as root, or the uids match"
				end
				
			end

	    super(iparams)    
	  end

	  ############################################################################
	  #
	  # start
	  #
	  # fork() and exec() the start_cmd
	  #
	  ############################################################################
	
	  def do_start(attempt_count)
	    info("do_start[#{attempt_count}] for #{self.name}")
	    
	    Process.fork do

				# close network descriptors
				NetUtil::post_fork()

				# start new session
				Process.setsid()

				# set environment cookie so we can be identified		
				hash=env_hash()
				ENV[ ProcessUtil::ENVIRONMENT_KEY ] = hash if(hash)
				
				# change user/group?
				if(@params[:run_user])

					current_uid=Process.euid()
					current_user=Etc.getpwuid(current_uid)
					
					if(current_uid != @params[:run_user].uid)
						Process.uid=@params[:run_user].uid
						Process.gid=@params[:run_user].gid
						Process.euid=@params[:run_user].uid
						Process.egid=@params[:run_user].gid
						ENV["HOME"]=@params[:run_user].dir
					end					
					
				end
				
				# change directory?
				Dir.chdir(@params[:start_dir])
	    
				# redirect inputs/outputs
				STDIN.reopen("/dev/null")		# - closing STDIN causes problems with apache
				file=@params[:log_file] ? @params[:log_file] : "/dev/null"
				STDOUT.reopen(file,"a")
				STDERR.reopen(file,"a")
	    
	    	# run!
	    	Process.exec(@params[:start_cmd])
	     
	    end
	    
	  end
	  
	  ############################################################################
	  #
	  # stop
	  #
	  # stop the process (either with -TERM or -KILL)
	  #
	  ############################################################################
	  
	  def do_stop(attempt_count)
	  
	  	kl=@params[:soft_kill_limit]
	  	mode = (kl && attempt_count >= kl) ? :hard : :soft

	    info("do_stop[#{attempt_count}]->#{mode} for #{self.name}")
	    
			if(mode == :soft)
				if(params[:stop_cmd])
					system(params[:stop_cmd])
					return
				end
			end	    
	    
	    # find all processes with matching hash
	    procs=ProcessUtil::processes[ env_hash ]
	    if(procs)
				procs.each do |pid|
					Process.kill({ :hard => "KILL", :soft => "TERM" }[mode],pid)
				end
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
			ProcessUtil::processes[env_hash] ? :up : :down	  
	  end

	  ############################################################################
	  #
	  # env_hash
	  #
	  # returns magic environment cookie that identifies processes belonging to
	  # this service.
	  #
	  ############################################################################
	  
		def env_hash()
			Digest::MD5.hexdigest( name )
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
	  
	end


	ServiceMgr::register_service_class(ProcessService)

end


