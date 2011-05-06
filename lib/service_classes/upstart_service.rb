############################################################################
#
# upstart_service.rb
#
# class representing a service controlled by upstart
#
############################################################################

require 'service'
require 'digest/md5'
require 'etc'
require 'process_service'
require 'process_util'

#<BRS> used to require dbus, but upstart doesn't seem to use it in Ubuntu Server
#require 'rubygems'
#gem 'ruby-dbus'
#require 'dbus'

module ProcessWanker

	class UpstartService < Service
		
		include Log

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def self.nice_name
			"upstart_service"
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	  def initialize(iparams)
		
			# extract parameters
			extract_params(
				iparams,
				[
					:job_name,
				])

			@job_name=@params[:job_name] || iparams[:name]
			
			super(iparams)
	  end

	  ############################################################################
	  #
	  # start
	  #
	  ############################################################################
	  
	  def do_start(attempt_count)
	  	debug("do_start #{self.name}")
			system("initctl start #{@job_name}")
	  end
	  
	  ############################################################################
	  #
	  # stop
	  #
	  ############################################################################
	  
	  def do_stop(attempt_count)
			system("initctl stop #{@job_name}")
  	end
	  
	  ############################################################################
	  #
	  # ping
	  #
	  # return run state of process
	  #
	  ############################################################################
	  
	  def do_ping
			status=`initctl status #{@job_name}`
			status.include?("running") ? :up : :down
	  end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
	end


	ServiceMgr::register_service_class(UpstartService)

end


