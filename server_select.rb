#!/usr/bin/env ruby
=begin
-------------------------------------------------------------------------------------
--  SOURCE FILE:    server_epoll.rb - A multi-threaded echo server using IO.select
--
--  PROGRAM:        server_epoll
--                ./server_epoll.rb [listening_port] 
--
--  FUNCTIONS:      Ruby Sockets, Ruby EventMachine(epoll)
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

## Variables
# String constants
SRV_MSG, MAX_CON, LOG_NAME, SRV_STOP, SRV_START =
    "^^ Server Output ^^", "Total clients connected",
    "server_epoll_log", "User shutdown received. Stopping Server.\n", 
    "Server started. Accepting connections.\n"
# default port and client tracking variables
default_port, @num_clients, @max_clients = 8005, 0, 0
# Variable locks,
@lock, @lock2, @lock3, @lock4, @lock5 = 
    Mutex.new, Mutex.new, Mutex.new, Mutex.new, Mutex.new
# output & data transfer key/value dictionary
@ctl_msg, @xfer = Hash.new, Hash.new
# stream arrays for select
@reading, @writing = Array.new, Array.new

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
        @lock3.synchronize do 
            File.open(LOG_NAME, 'a') { |f| f.write ("#{time}: #{msg}") }
        end
    rescue Exception => e
        # problem opening or writing to file
        print_exception(e)
    end
end

# Sets up the listening server for the program and 
# initializes output control loop thread
# * *Args*    :
#   - +port+ -> port to turn the listening server on
# * *Returns* :
#   - +srv+ -> server listening socket
#   - +t+ -> thread id of output control loop
#
def init_srv(port)
    begin
        srv = TCPServer.open(port)
    rescue Exception => e
        #problem opening listening socket..probs should exit
        print_exception(e)
        exit!
    end 
    log(SRV_START)

    t = Thread.new {
        while 1
            system "clear"
            output_print
            puts SRV_MSG
            @lock.synchronize do
                puts "SERVER CONNECTIONS> #{@num_clients}"
            end
            sleep 0.4

            # repeat output with additional .
            # shows that its "awake"
            system "clear"
            output_print
            puts SRV_MSG
            @lock.synchronize do
                puts "SERVER CONNECTIONS> #{@num_clients} ."
            end
            sleep 0.4
        end
    }
    return srv, t
end

# Adds a message with a key to the output dictionary
# * *Args*    :
#   - +k+ -> key to store message under
#   - +v+ -> message to store
#
def output_append(k, v)
    @lock2.synchronize do 
        @ctl_msg[k] = v
    end
end

# Removes a message from the output dictionary using the key
# * *Args*    :
#   - +k+ -> key on which to remove message
#
def output_remove(k)
    @lock2.synchronize do 
        @ctl_msg.delete(k)
    end
end

# Iterates the output dictionary and outputs only the values
#
def output_print
    @lock2.synchronize do 
        @ctl_msg.each {|k, v| puts v}
    end
end

# Adds a message with a key to the transfer dictionary.
# This is used to track the amount of data received
# and sent to each client.
# * *Args*    :
#   - +k+ -> key to store message under
#   - +v+ -> message to store
#
def xfer_append(k, v)
    @lock4.synchronize do 
        if @xfer[k] == nil # does not exist
            @xfer[k] = v
        else               # exists
            @xfer[k] += v
        end
    end
end

# Logs the contents of the xfer dictionary.
# This is will allow to statistical tracking
# of data received and sent per client.
#
def xfer_out
    @lock4.synchronize do
        File.open(LOG_NAME, 'a') { |f| 
            @xfer.each { |k, v|
                f.write("#{k},#{v}\n")
            }
        }
    end
end

# Totals the xfer stats stored in the xfer dictionary.
#
def xfer_total
    t_in, t_out = 0, 0
    @lock4.synchronize do
        @xfer.each { |k, v|
            if k.include? "_IN"
                t_in += v
            elsif k.include? "_OUT"
                t_out += v
            end     
        }
    end

    xfer_append("Total bytes transfered in", t_in)
    xfer_append("Total bytes transfered out", t_out)
    xfer_append("Total bytes transfered", t_in+t_out)
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

# thread id of ui control loop saved incase need to use it in future
# program iterations
@server, t_id = init_srv(port)
@reading.push(@server)

# Server loop
loop {
    begin 
        @lock5.synchronize {
            # blocking call?
            @readable, writable = IO.select(@reading, @writing)
        }
    rescue IOError
        # assume this is coming from select trying to read sockets before
        # thread has a chance to close it
    rescue SignalException => c # ctrl-c => SERVER SHUTDOWN
                log(SRV_STOP)
                xfer_append(MAX_CON, @max_clients)
                xfer_total
                xfer_out
                system("clear")
                puts SRV_STOP
                exit!
    rescue Exception => e
        print_exception(e)
    end
    @readable.each do |socket|
        if socket == @server
            begin
                Thread.start(@server.accept_nonblock) do |c|
                    @lock5.synchronize {
                        @reading.push(c) # add to array of sockets
                    }
                    
                    sock_domain, remote_port, 
                        remote_hostname, @remote_ip = c.peeraddr
                    # local to thread client ID
                    client_num = 0
                    @lock.synchronize do
                        @num_clients += 1
                        @max_clients += 1
                        client_num = @num_clients
                    end
                    client = c.peeraddr[3] # remote_hostname
                    client_id = "#{client}-#{client_num}-#{rand(0..500)}"
                    output_append(client_id, "#{client} is connected")
                    begin
                        loop do
                            line = c.readline
                            xfer_append("#{client_id}_IN", line.bytesize)
                            c.puts(line)
                            xfer_append("#{client_id}_OUT", line.bytesize)
                            log("#{client_id}: #{line}")
                        end
                    rescue EOFError # client disconnected
                        c.close
                        @lock5.synchronize {
                            @reading.delete(c)
                        }
                        @lock.synchronize do
                            @num_clients -= 1
                        end
                        output_remove(client_id)
                    rescue Exception => e
                        # problem reading or writing to/from client
                        print_exception(e)
                    end    
                end
            rescue Exception => e
                #problem opening client socket
                print_exception(e)
            end
        end
    end
}

## Main end
