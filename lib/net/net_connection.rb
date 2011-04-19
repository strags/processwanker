############################################################################
#
# net_connection.rb
#
# handles the physical TCP/SSL connection between client(s) and daemon(s)
#
############################################################################

require 'openssl'
require 'config'
require 'thread'
require 'util'

module ProcessWanker
	
  ############################################################################
  #
  #
  #
  ############################################################################

	class NetConnection
		include Log
	
		attr_accessor				:ssl_connection	
		attr_accessor				:user
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def initialize(ssl_connection)
			@write_mutex=Mutex.new
			@ssl_connection=ssl_connection
			@read_thread = Thread.new { read_proc }
			@user = ssl_connection.peer_cert.subject.to_a.select { |x| x[0]=="CN" }.map { |x| x[1] }[0]
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def wait
			@read_thread.join
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def send_msg(msg)

			@write_mutex.synchronize do			
				debug("sending message #{msg.inspect}")
				begin
					data=Marshal.dump(msg)
					length=[data.length].pack("N")
					@ssl_connection.write(length + data)
				rescue Exception => e
					on_close()
				end
			end
			
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def close_rudely()
			ProcessWanker::with_logged_rescue("close_rudely",Log::DEBUG) do
				@ssl_connection.io.close()
			end
			disconnect()
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def disconnect()
			on_close()
			if(Thread.current != @read_thread)
				@read_thread.join
			end
		end

	  ############################################################################
	  #
	  #
	  #
	  ############################################################################

		def read_proc
			while(@ssl_connection)
				read_connection()
			end
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def read_connection()
			begin
				length=@ssl_connection.read(4)
				raise "closed" if(length.length != 4)
				length=length.unpack("N")[0]
				data=@ssl_connection.read(length)
				raise "closed" if(data.length != length)
				msg=Marshal.load(data)
				on_msg(msg)
			rescue Exception => e
				on_close()
			end
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def on_close()
			ProcessWanker::with_logged_rescue("on_close",Log::DEBUG) do
				@ssl_connection.close if(@ssl_connection)
			end
			@ssl_connection=nil
		end
	
	  ############################################################################
	  #
	  #
	  #
	  ############################################################################
	
		def on_msg(msg)
#			puts msg.inspect
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
