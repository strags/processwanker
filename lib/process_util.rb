############################################################################
#
# process_util.rb
#
# process management utilities
#
############################################################################

require 'service_mgr'
require 'log'

module ProcessWanker
	module ProcessUtil
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
	  ENVIRONMENT_KEY = "PWANKER"
		@@all_processes={}
	  @@processes={}
	  @@known_hashes={}
	  @@unknown_history={}
		@@os=`uname -a`.split[0].downcase.to_sym
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def build_known_hashes()
			# build hash of all known environment hashes
			@@unknown_history={}
			@@known_hashes={}
			ServiceMgr::instance.services_by_name.each do |n,s|
				next unless(s.respond_to?(:env_hash))
				@@known_hashes[ s.env_hash ]=s
			end
		end	
		module_function				:build_known_hashes
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def scan_processes
			if(@@os == :linux)
				scan_processes_linux()
			elsif(@@os == :darwin)
				scan_processes_osx()
			else
				raise "Bad os?"
			end
		end
		module_function				:scan_processes
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	  def scan_processes_linux

	  	all_procs={}
			procs={}  	
			
	    Dir.glob("/proc/*/environ").each do |p|
  			pid=p.split("/")[2].to_i
				all_procs[pid]=true
	    	begin
	    		File.read(p).split("\000").each do |env_item|
	    			key,value=env_item.split("=")
	    			next unless(key == ENVIRONMENT_KEY)
	    			procs[value] ||= []
	    			procs[value] << pid
	    		end
	    	rescue Errno::EACCES => e
	    		next
	    	rescue Errno::ENOENT => e
	    		next
		rescue Exception => e
			next
	    	end
	    end
	    
			@@all_processes=all_procs
	    @@processes=procs
	    
	    procs
	  end
	  module_function     :scan_processes_linux
	  
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def scan_processes_osx
	  	all_procs={}
			procs={}  	
			
			`ps axe`.split("\n").each do |l|
				s=l.split
				next if(s[0] == "USER")
				pid=s[0].to_i
				all_procs[pid]=true
				(5..(s.length-1)).each do |q|
					key,value=s[q].split("=")
					next unless(key == ENVIRONMENT_KEY && value)
					procs[value] ||= []
					procs[value] << pid
				end
			end
			
			@@all_processes=all_procs
	    @@processes=procs
			procs
		end
		module_function		:scan_processes_osx
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
		def reap
			begin
				while(true)
          break if(!Process::waitpid(-1,Process::WNOHANG))
				end
			rescue Exception => e
			end
		end
		module_function			:reap	  
	  
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
		def processes
			@@processes
		end  
		module_function			:processes
	  
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
		def all_processes
			@@all_processes
		end  
		module_function			:all_processes
	  
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def kill_unknown
		
			# build list of pids that we ought to kill
			unknown_pids={}
			@@processes.each do |p,v|
				next if(@@known_hashes[p])
				v.each do |vv|
					unknown_pids[vv]=true
					@@unknown_history[vv] ||= { :last_kill_time => Time.at(0), :kcount => 0 }
				end
			end
			
			# clean out any unknown_history entries that no longer appear
			@@unknown_history.keys.select { |x| !unknown_pids[x] }.each { |d| @@unknown_history.delete(d) }

			# process entries
			now=Time.now()
			@@unknown_history.each do |pid,state|

				elapsed=now - state[:last_kill_time]
				next if(elapsed < 5)

				mode=(state[:kcount] < 3) ? "TERM" : "KILL"
				Log::info("kill #{mode} #{pid}")
				Process.kill(mode,pid)
				state[:last_kill_time]=now
				state[:kcount] += 1
			end
			
		end
		module_function			:kill_unknown

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
