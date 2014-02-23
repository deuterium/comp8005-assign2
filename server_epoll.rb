#!/usr/bin/env ruby
=begin
-------------------------------------------------------------------------------------
--  SOURCE FILE:    server_epoll.rb - A multi-threaded echo server using IO.select
--
--  PROGRAM:        server_epoll
--                ./server_epoll.rb [listening_port] 
--
--  FUNCTIONS:      Ruby Sockets, Ruby EventMachine(epoll)
--                                http://rubyeventmachine.com/
--
--  DATE:           February 4, 2014
--
--  REVISIONS:      See development repo: https://github.com/deuterium/comp8005-assign2
--
--  DESIGNERS:      Chris Wood - chriswood.ca@gmail.com
--
--  PROGRAMMERS:    Chris Wood - chriswood.ca@gmail.com
--
--  NOTES:
--  The program will accept TCP connections from clients.
--  The program will read data from the client socket and simply echo it back.
--  This server program is multi-threaded, with a event driven accept call.
--  1 thread is used for a server output thread. Data should be thread-safe
--  with the use of mutexes.
--  This server application can be used with the aaccompanying threaded 
--  client: client.rb
---------------------------------------------------------------------------------------
=end

require 'socket'
require 'thread'
require 'eventmachine'

## Variables
# String constants
SRV_MSG, MAX_CON, LOG_NAME, SRV_STOP, SRV_START =
    "^^ Server Output ^^", "Total clients connected",
    "server_epoll_log", "User shutdown received. Stopping Server.\n", 
    "Server started. Accepting connections.\n"
# default port and client tracking variables
default_port, $num_clients, $max_clients = 8005, 0, 0
# output & data transfer key/value dictionary
$ctl_msg, $xfer = Hash.new, Hash.new

## Functions
# Returns the server's time
# * *Returns* :
#   - the system time (format YYYY-MM-DD HH:MM:SS)
#
def time
    t = Time.now
    return t.strftime("%Y-%m-%d %H:%M:%S")
end

# Prints an exception's error to STDOUT
# * *Args*    :
#   - +e+ -> exception to have message output
#
def print_exception(e)
    puts "error: #{e.message}"
end

# Log message to external file, time prepended
# * *Args*    :
#   - +msg+ -> msg to write to log
#
def log(msg)
    begin
        File.open(LOG_NAME, 'a') { |f| f.write ("#{time}: #{msg}") }
    rescue Exception => e
        # problem opening or writing to file
        print_exception(e)
    end
end

# Initializes output control loop thread
# * *Returns* :
#   - +t+ -> thread id of output control loop
#
def init_disp
    log(SRV_START)

    t = Thread.new {
        while 1
            system "clear"
            output_print
            puts SRV_MSG
            puts "SERVER CONNECTIONS> #{$num_clients}"
            sleep 0.4

            # repeat output with additional .
            # shows that its "awake"
            system "clear"
            output_print
            puts SRV_MSG
            puts "SERVER CONNECTIONS> #{$num_clients} ."
            sleep 0.4
        end
    }
    return t
end

# Adds a message with a key to the output dictionary
# * *Args*    :
#   - +k+ -> key to store message under
#   - +v+ -> message to store
#
def output_append(k, v)
    $ctl_msg[k] = v
end

# Removes a message from the output dictionary using the key
# * *Args*    :
#   - +k+ -> key on which to remove message
#
def output_remove(k)
        $ctl_msg.delete(k)
end

# Iterates the output dictionary and outputs only the values
#
def output_print
    $ctl_msg.each {|k, v| puts v}
end

# Adds a message with a key to the transfer dictionary.
# This is used to track the amount of data received
# and sent to each client.
# * *Args*    :
#   - +k+ -> key to store message under
#   - +v+ -> message to store
#
def xfer_append(k, v)
    if $xfer[k] == nil # does not exist
        $xfer[k] = v
    else               # exists
        $xfer[k] += v
    end
end

# Logs the contents of the xfer dictionary.
# This is will allow to statistical tracking
# of data received and sent per client.
#
def xfer_out
    File.open(LOG_NAME, 'a') { |f| 
        $xfer.each { |k, v|
            f.write("#{k},#{v}\n")
        }
    }
end

# Totals the xfer stats stored in the xfer dictionary.
#
def xfer_total
    t_in, t_out = 0, 0
    $xfer.each { |k, v|
        if k.include? "_IN"
            t_in += v
        elsif k.include? "_OUT"
            t_out += v
        end     
    }

    xfer_append("Total bytes transfered in", t_in)
    xfer_append("Total bytes transfered out", t_out)
    xfer_append("Total bytes transfered", t_in+t_out)
end

# Module to be used with EventMachine. Provides common namespace for methods
# that are commonly called by the EventMachine framework.
module EchoServer
    def post_init
        $num_clients += 1
        $max_clients += 1

        @client = get_peername[2,6].unpack("nC4").join(",") # remote_hostname
        #@test = client
        output_append(@client, "#{@client} is connected")
    end

    def receive_data data
        #client = get_peername[2,6].unpack("nC4").join(",") # remote_hostname
        xfer_append("#{@client}_IN", data.bytesize)
        send_data data
        xfer_append("#{@client}_OUT", data.bytesize)
        log("#{@client}: #{data}")
        #close_connection()
    end

    def unbind
        $num_clients -= 1
        output_remove(@client)
    end
end


## Main Start
STDOUT.sync = true

if ARGV.count > 1
    puts "Proper usage: ./server.rb [listening_port]"
    exit
elsif ARGV.empty? # default port
    port = default_port
else
    port = ARGV[0] # custom port
    ARGV.clear
end

# start display thread
t_id = init_disp

# Server loop; Note that this will block current thread.
begin 
    EventMachine.epoll
    EventMachine.run {
      EventMachine.start_server "127.0.0.1", port, EchoServer
    }
rescue SignalException => c # ctrl-c => SERVER SHUTDOWN
    log(SRV_STOP)
    xfer_append(MAX_CON, $max_clients)
    xfer_total
    xfer_out
    system("clear")
    puts SRV_STOP
    exit!
rescue Exception => e
    print_exception(e)
end
## Main end
