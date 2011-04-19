############################################################################
#
# events.rb
#
# handle dispatching of events to event hooks
#
############################################################################

require 'log'
require 'util'
require 'net/smtp'

module ProcessWanker
	
  ############################################################################
  #
  # basic event
  #
  ############################################################################
  
	class Event
	
	  ############################################################################
	  #
	  # properties
		#
		# a set of useful information for the handler to process
	  #
	  ############################################################################
	  
		attr_accessor				:type
		attr_accessor				:service
		attr_accessor				:service_name
		attr_accessor				:service_stats
		attr_accessor				:service_state
		attr_accessor				:time
		
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def self.dispatch(type,service)
			
			Log::debug("dispatching event #{type} for service #{service.name}")
			
			e=Event.new()
			e.type=type
			e.service=service
			e.service_name=service.name
			e.service_stats={}
#			e.service_stats=service.stats
			e.service_state=service.current_state
			e.time=Time.now

			# build array of hooks, from innermost to outermost
			stop=false
			hooks_lists=service.config_node.find_attributes("hooks")
			hooks_lists.each do |hooks|
				hooks.each do |hook|
					
					next unless(hook.pattern == type)
					context=EventHookContext.new
					context.service=service
					context.event=e
					
					ProcessWanker::with_logged_rescue("hook for event #{e.type} #{e.service.name}") do
						context.instance_eval(&hook.block)
					end
					
					stop=context.should_stop_hooks
					if(stop)
						break
					end
				end
				break if(stop)
			end
			
		end
	
	end


  ############################################################################
  #
  # EventHookContext is the context in which a hook executes
	#
	# it has an event member, and a set of helper functions for handling
	# notifications, etc...
  #
  ############################################################################
  
  class EventHookContext
	
		include Log
	
		attr_accessor				:service
		attr_accessor				:event
		attr_accessor				:should_stop_hooks
	
	  ############################################################################
	  #
	  # helpers
	  #
	  ############################################################################

		def email()
			
			# find smtp config
			smtp_config=service.config_node.find_attributes("smtp").first
			if(!smtp_config)
				Log::error("attempting to send an email, but no SMTP configuration found")
				return
			end
			from_user,from_domain=smtp_config.from_addr.split("@")
			
			# construct email
			@email_addresses=smtp_config.to_addrs.clone
			@email_subject="ProcessWanker event: #{@event.type} from #{event.service_name}"
			@email_body="At #{@event.time}, #{event.service_name} triggered a <#{@event.type}> event\n"
			@email_body << "The current state is #{@event.service_state}.\n"
			@email_body << "Service stats:\n"
			@event.service_stats.each do |k,v|
				@email_body << "  #{sprintf("%-20s",k)} : #{v}\n"
			end
			@email_body << "\n"
			
			# allow configuration to override some values
			if(block_given?)
				yield
			end
			
			# send the email
			Log::debug("SENDING EMAIL: #{@email_addresses.inspect}")
			Log::debug(puts "Subject: #{@email_subject}")
			Log::debug(puts "Body: \n#{@email_body}")
			
			msg="From: #{smtp_config.from_addr}\n"
			msg << "To: #{@email_addresses.join(",")}\n"
			msg << "Subject: #{@email_subject}\n\n"
			msg << @email_body
			
			#
			# TODO: consider putting this in a different thread, or at least adding a timeout
			#
			
			ProcessWanker::with_logged_rescue("sending emails via #{smtp_config.server}") do
				
				smtp=Net::SMTP.new(smtp_config.server,smtp_config.port)
				
				if(smtp_config.secure == :tls || smtp_config.secure == :ssl)
					smtp.enable_tls
				elsif(smtp_config.secure == :starttls)
					smtp.enable_starttls
				end
				
				smtp.start(from_domain,
				           smtp_config.userid,
				           smtp_config.password,
				           smtp_config.auth_method)
				@email_addresses.each do |to|
					ProcessWanker::with_logged_rescue("sending email to #{to}") do
						smtp.send_message(msg,smtp_config.from_addr,to)
					end
				end
				smtp.finish
			end
			
			Log::debug("sent email")
			
		end

	  ############################################################################
	  #
	  # email helpers
	  #
	  ############################################################################

		def email_to_addrs(*addr)
			@email_addresses += addr
		end
		
		def email_subject(subject)
			@email_subject = subject
		end
		
		def email_body(body)
			@email_body=body
		end
		
	  ############################################################################
	  #
	  # general helpers
	  #
	  ############################################################################

		def stop_hooks
			@should_stop_hooks=true
		end
		
		def start
			info("hook requested service start")
			@event.service.set_want_state(:up)
		end

		def stop
			info("hook requested service stop")
			@event.service.set_want_state(:down)
		end

		def restart
			info("hook requested service restart")
			@event.service.set_want_state(:restart)
		end
		
		def ignore
			info("hook requested service ignore")
			@event.service.set_want_state(:ignore)
		end
		
	end
	
end
