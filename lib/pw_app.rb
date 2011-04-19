#!/usr/bin/env ruby
############################################################################
#
# pw_app.rb
#
# main commandline entry-point for pw application
#
############################################################################

############################################################################
#
# set load paths
#
############################################################################

MY_PATH=File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << MY_PATH
$LOAD_PATH << File.join( MY_PATH , "config" )
$LOAD_PATH << File.join( MY_PATH , "net" )

############################################################################
#
# requires
#
############################################################################

require 'service_mgr'
require 'process_util'
require 'config'
require 'net_util'
require 'net_server'
require 'net_client'
require 'optparse'
require 'log'
require 'thread'

require 'rubygems'
gem 'highline'
require 'highline'

module ProcessWanker

	############################################################################
	#
	# the main ProcessWanker application
	#
	############################################################################

	class Application
		include Log

		DEFAULT_WAIT=60

		############################################################################
		#
		#
		#
		############################################################################

	  def initialize()
    
			#
			# parse options
			#
		
			parse_opts()
		
			#
			# generate certs/keys?
			#
		
			if(@options[:generate_ca])
				generate_ca()
				exit
			end

			if(@options[:generate_user])
				generate_user()
				exit
			end

			Config::set_config_path(@options[:config]) if(@options[:config])

			#
			# run as daemon?
			#

			if(@options[:daemon])
				start_daemon()
				exit
			end
			
			#
			# list known clusters/hosts?
			#

			cp=Config::get_config_path
			raise "no such config file: #{cp}" if(!File.exist?(cp))
			@config=Config::load_config(cp)  # .new( :client, File.read(cp) )
			raise "no client config provided" if(!@config.client)
			if(@options[:list_clusters])
				list_clusters()
				exit
			end

			#
			# ok... it's a remote command 
			#
			
			execute_remote()
			
	  end
  
		############################################################################
		#
		#
		#
		############################################################################

		def parse_opts()
		
			options={}
			options[:actions]=[]
		
			optparse=OptionParser.new do |opts|
			
				opts.on(nil,'--help','Display this screen') do
					puts
					puts opts
					puts
					puts "  SERVICE_SPEC can be a 'all', a name, a regular expression, or a tag - eg. tag:db"
					puts "  It can also be a comma-separated list of all of the above. Prefixing a string/regex/tag with"
					puts "  a tilde (~) has the meaning 'except'."
					puts
					exit
				end
			
				opts.on("-l","--list [SERVICE_SPEC]","Show the status of the given service(s)") do |v|
					options[:actions] << { :cmd => :list, :spec => v || "all" }
				end

				opts.on("-s","--start SERVICE_SPEC","Start the given service(s)") do |v|
					options[:actions] << { :cmd => :start, :spec => v || "all" }
				end

				opts.on("-k","--kill SERVICE_SPEC","Stop the given service(s)") do |v|
					options[:actions] << { :cmd => :stop, :spec => v || "all" }
				end
			
				opts.on("-i","--ignore SERVICE_SPEC","Ignore the given service(s)") do |v|
					options[:actions] << { :cmd => :ignore, :spec => v || "all" }
				end
			
				opts.on("--stop SERVICE_SPEC","Stop the given service(s)") do |v|
					options[:actions] << { :cmd => :stop, :spec => v || "all" }
				end
			
				opts.on("-r","--restart SERVICE_SPEC","Restart the given service(s)") do |v|
					options[:actions] << { :cmd => :restart, :spec => v || "all" }
				end

				opts.on("-w","--wait SECS",Integer,"Wait SECS seconds for service(s) to reach requested state, default (#{DEFAULT_WAIT})") do |v|
					options[:wait] = v
				end

				opts.on("--sequential [DELAY_SECS]",Float,"Execute all operations sequentially, with optional delay between them") do |v|
					options[:sequential]=v || 0.0
				end

				opts.on("--reload","Reload configuration") do
					options[:actions] << { :cmd => :reload }
				end
			
				opts.on("--terminate","Terminate daemon") do
					options[:actions] << { :cmd => :terminate }
				end
			
				opts.on("-c","--cluster NAME","Select a cluster to control") do |v|
					options[:cluster]=v
				end
			
				opts.on("-h","--host HOST","Select a single host to control") do |v|
					options[:host]=v
				end

				opts.on("-g","--config FILE","Specify configuration file to use (#{Config::get_config_path})") do |v|
					options[:config]=v
				end
			
				opts.on("--list-clusters","Display a list of known clusters and hosts") do
					options[:list_clusters]=true
				end
			
				opts.on("-d","--daemon","Run in the background as a server") do
					options[:daemon]=true
				end
			
				opts.on("-f","--foreground","Don't detach - stay in the foreground (useful only with -d option)") do
					options[:foreground]=true
				end
			
				opts.on("--notboot","Don't start all local services automatically (useful only with the -d option)") do
					options[:notboot]=true
				end
			
				opts.on("--generate-ca","Generate CA cert/key (requires --output-prefix)") do |v|
					options[:generate_ca]=v
				end
			
				opts.on("--output-prefix PATH","Specify output file prefix for .crt and .key") do |v|
					options[:output_prefix]=v
				end
			
				opts.on("--ca-prefix PATH","Specify input file location prefix for the CA certificate and key") do |v|
					options[:ca_prefix]=v
				end
			
				opts.on("--require-passphrase","Use a passphrase to encrypt any generated private keys") do
					options[:require_passphrase]=true
				end
			
				opts.on("--generate-user NAME","Generate client cert/key - requires (--ca-prefix and --output-prefix)") do |v|
					options[:generate_user]=v
				end
			
				opts.on("--debug","Debug hook") do |v|
					options[:actions] << { :cmd => :debug }
				end
			
				opts.on("--log","Log file (for pw output only)") do |v|
					options[:log_file] = v
        end
        
				opts.on("--verbose","Debugging enabled") do |v|
					Log::set_level(Log::DEBUG)
				end
			
			
			end
		
			extra=optparse.parse!

			if(extra.length > 0)
				puts "warning: ignoring extra params: #{extra.join(" ")}"
			end
		
			@options=options
				
			
		end

		############################################################################
		#
		#
		#
		############################################################################

		def generate_ca()
			raise "no --output-prefix specified" if(!@options[:output_prefix])
			pass=nil
			if(@options[:require_passphrase])
				pass=HighLine.new.ask("Password (for encrypting output key) : ") { |x| x.echo=false }.strip
				p2=HighLine.new.ask("(verify)                             : ") { |x| x.echo=false }.strip
				raise "passwords don't match" if(pass != p2)
			end
			
			ProcessWanker::NetUtil::generate_ca(@options[:output_prefix],pass)
		end

		############################################################################
		#
		#
		#
		############################################################################

		def generate_user()
			raise "no --output-prefix specified" if(!@options[:output_prefix])
			raise "no --ca-prefix specified" if(!@options[:ca_prefix])
			pass=nil
			if(@options[:require_passphrase])
				pass=HighLine.new.ask("Password (for encrypting output key) : ") { |x| x.echo=false }.strip
				p2=HighLine.new.ask("(verify)                             : ") { |x| x.echo=false }.strip
				raise "passwords don't match" if(pass != p2)
			end
			
			ProcessWanker::NetUtil::generate_cert(
				@options[:ca_prefix],
				@options[:output_prefix],
				@options[:generate_user],
				pass)
				
		end

		############################################################################
		#
		#
		#
		############################################################################

		def start_daemon
			
			info("starting daemon")			

			# create servicemgr
			ServiceMgr.new()

			# load daemon config
      puts Config::get_config_path()
#			@config=Config.new( :daemon, File.read( Config::get_config_path ) )
			@config=Config::load_config( Config::get_config_path )  # .new( :client, File.read(cp) )
			raise "no daemon config provided" if(!@config.daemon)

			# apply config
			ServiceMgr::instance().apply_config(@config,@options[:notboot])

			# daemonize?			
			if(!@options[:foreground])

        puts "Going to background..."
        
        Process.fork do
          
    			# start net server
    			NetServer.new(@config)


  				# redirect inputs/outputs
  				file=@options[:log_file] || @config.daemon.log_file || "/var/log/pw.log"
          puts "logging to #{file}"
          begin
            FileUtils.mkdir_p( File.dirname(file) )
            File.open(file,"a") { |x| x.puts "ProcessWanker starts" }
            STDERR.reopen(file,"a")
            STDOUT.reopen(file,"a")
    				STDIN.reopen("/dev/null")
          rescue Exception => e
            raise "unable to open log file #{file}"
          end
          
    			Log::set_level(Log::DEBUG)
          
          # start new session
          Process.setsid()
          
    			# run
    			ServiceMgr::instance().run()
          
        end
        
      else
        
  			# start net server
  			NetServer.new(@config)


        # just run in foreground
        ServiceMgr::instance().run()
        
      end
			
		
		end

		############################################################################
		#
		#
		#
		############################################################################

		def match_hosts(hostspec,cluster_name)
			cluster_name ||= "default"
			cluster=@config.client.get_cluster(cluster_name)
			raise "no such cluster: #{cluster_name}" if(!cluster)

			hosts=[]
			cluster.hosts.each { |k,v| hosts << v if(!hostspec || v.matches_spec(hostspec)) }
			hosts
		end

		############################################################################
		#
		#
		#
		############################################################################

		def list_clusters()
			puts "clusters:"
			@config.client.clusters.clusters.each do |cname,cluster|
				puts " [#{cname}]"
				c=cluster
				c.hosts.each do |hname,h|
					printf("    %-30s",hname)
					printf("    %-30s","#{h.hostname}:#{h.port}")
					h.tags.each { |t| printf("%s ",t) }
					puts
				end
			end
			exit
		end

		############################################################################
		#
		#
		#
		############################################################################

		def execute_remote()
			
			#
			# match hosts
			#
			
			hosts=match_hosts(@options[:host],@options[:cluster])
			
			#
			# set defaults
			#
			
			if(@options[:actions].length == 0)
				@options[:actions] << { :cmd => :list, :spec => "all" }
			end
			@options[:wait] ||= DEFAULT_WAIT

			#
			# execute each action sequentially
			#
			
			@options[:actions].each do |action|
			
				#
				# hit each host in turn, or concurrently
				#			
			
				if(@options[:sequential])
					hosts.each do |host|
						execute_host_action(host,action)
					end
				else
					threads=[]
					hosts.each do |host|
						threads << Thread.new do 
							execute_host_action(host,action)
						end
					end
					threads.each { |t| t.join }
				end
			end
			
		end

		############################################################################
		#
		#
		#
		############################################################################

		def execute_host_action(host,action)
			begin
				client=NetClient.new(host)
				req=action.merge(
					{
						:wait				=> @options[:wait],
						:sequential	=> @options[:sequential]
					})
				client.send_msg(req)
				resp=client.wait
			rescue Exception => e
				puts("[#{host.name}]: connection failure")
				debug(e.message)
				e.backtrace { |x| debug(x) }
			end

			if(resp)
				display_response(resp,host)			
			end
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		@@display_mutex=Mutex.new()
	
		def display_response(resp,host)

			@@display_mutex.synchronize do
				
	      if(resp[:services])
					puts
					printf("[%s]",host.name)
					if(host.tags.length>0)
						puts " - (#{host.tags.join(",")})" 
					else
						puts
					end
					printf("    %-30s %-30s %-20s %s\n","name","state","want-state","tags")
					groups=resp[:services].values.map { |x| x[:group_name] }.uniq.sort
					groups.each do |grp|
						puts "  [group: #{grp}]" if(groups.length > 1)
						services=resp[:services].values.select { |x| x[:group_name] == grp }
						services.sort! { |a,b| a[:name] <=> b[:name] }
						services.each do |s|
							show=s[:show_state]
							show << " (suppressed)" if(s[:suppress])
							printf("    %-30s %-30s %-20s %s\n",
								s[:name],
								show,
								s[:want_state],
								s[:tags].join(" ")
							)
						end
					end			
					
					puts
				end
			
				if(resp[:counts])
						resp[:counts].keys.sort.each do |name|
							printf("%-50s %d\n",name,resp[:counts][name])
						end
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


############################################################################
#
#
#
############################################################################

ProcessWanker::Application.new()

