############################################################################
#
# service_mgr.rb
#
# the core of the application
#
############################################################################

require 'process_util'
require 'config'
require 'service'

module ProcessWanker
	class ServiceMgr
	
		include Log
		
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		CLASS_SUBDIR 	= "service_classes"
		CLASS_DIR			=	File.join(File.dirname(File.expand_path(__FILE__)),CLASS_SUBDIR)
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	  attr_accessor         :services_by_name
	  attr_accessor					:tick_count
		attr_accessor					:service_classes
		attr_accessor					:reload_config
		attr_accessor					:terminate
	  
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	  class << self
	    def instance
	      @@instance
	    end
	    def register_service(service)
	      @@instance.register_service(service)
	    end
	    def register_service_class(service_class)
	      @@instance.register_service_class(service_class)
	    end
	  end
	  	  
	  ############################################################################
	  #
	  # initialize
	  #
	  ############################################################################
	
	  def initialize()
	    @@instance=self
	    @services_by_name={}
			@service_classes={}
	    @tick_count=0
	
	    ProcessUtil::scan_processes()
			load_classes()
	  end
	  
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def load_classes()
			$LOAD_PATH << CLASS_DIR unless($LOAD_PATH.include?(CLASS_DIR))
			Dir.glob( File.join(CLASS_DIR,"*.rb") ).each do |fn|
				require( File.basename(fn,".rb") )
			end
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	  def register_service(service)
	  	raise "service is missing name" if(!service.name)
			raise "service #{service.name} is multiply defined" if(@services_by_name[service.name])  
	    @services_by_name[service.name]=service
	  end
	  
		############################################################################
	  #
	  #
	  #
	  ############################################################################
	
	  def register_service_class(service_class)
			@service_classes[ service_class.nice_name ]=service_class
		end
	
	  ############################################################################
	  #
	  # main tick function
	  #
	  ############################################################################
	
	  def tick()
	    
	    # scan processes... and kill anything we don't recognize
	    ProcessUtil::scan_processes()
	    ProcessUtil::kill_unknown()
	    ProcessUtil::reap()
	    
	    # tick each service in turn
	    @services_by_name.values.each do |service|
	      service.tick()      
	    end
	    
	    @tick_count += 1
	    
	  end
	  
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def match_services(spec)
			matched={}
			@services_by_name.each do |sn,s|
				matched[sn]=s if(s.matches_spec(spec))
			end
			matched
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	  
		def apply_config(cfg,notboot=true)

	    @services_by_name={}

			cfg.daemon.services.each do |group_name,services|
				services.services.each do |name,service|
					params=service.params.merge({ :name => service.name, :group_name => group_name })
					if(!notboot)
						params[:initial_state]=:up
					end
					svc=service.klass.new(params)
					
					# the service will register itself
					# we must store its config block
					svc.config_node=service
					
				end
			end
			
			@services_by_name.each do |n,v|
				v.resolve_dependencies()
			end
			
			ProcessUtil::build_known_hashes()

		end	  
	  
		############################################################################
		#
		#
		#
		############################################################################

	  def run()
	  	
	  	while(true)
	  		
				tick()
				sleep(1)

				#
				# check for requests
				#
				
				if(@reload_config)
					info("reloading configuration")
					ProcessWanker::with_logged_rescue("ServiceMgr - reloading configuration") do
						c=Config::load_config(Config::get_config_path)
						apply_config(c)
					end
					@reload_config=false
				end
				
				if(@terminate)
					info("terminating")
					break
				end

	  	end
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
end
	
