#!/usr/bin/ruby
=begin
-------------------------------------------------------------------------------------
--  SOURCE FILE:    server_mt.rb - A multi-threaded echo server
--
--  PROGRAM:        server_mt
--                ./server.rb [listening_port] 
--
--  FUNCTIONS:      
--
--  DATE:           February 4, 2014
--
--  REVISIONS:      (Date and Description)
--                  none, initial version
--
--
--  DESIGNERS:      Chris Wood - chriswood.ca@gmail.com
--
--  PROGRAMMERS:    Chris Wood - chriswood.ca@gmail.com
--
--  NOTES:
--  The program will accept TCP connections from clients.
--  The program will read data from the client socket and simply echo it back.
--  This server program is multi-threaded, with a blocking server accept call.
--  1 thread is used for a server output thread. Data should be thread-safe
--  with the use of mutexes.
--  This server application can be used with the aaccompanying threaded 
--  client: client.rb
---------------------------------------------------------------------------------------
=end

require 'socket'

#String constants, default program port, client count
SRV_MSG, default_port, @num_clients = "^^ Server Output ^^", 8005, 0
#Variable locks, output key, value dictionary
@lock, @lock2, @ctl_msg = Mutex.new, Mutex.new, Hash.new

## Functions
# Returns the server's time
# * *Returns* :
#   - the system time (format YYYY-MM-DD HH:MM:SS)
#
def time
    t = Time.now
    return t.strftime("%Y-%m-%d %H:%M:%S")
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
    #
    t = Thread.new {
        while 1
            system "clear"
            @mutex.synchronize do
                output_print
                puts SRV_MSG
                puts "SERVER CONNECTIONS> #{@num_clients}"
            end
            
            sleep 0.4
            system "clear"
            @mutex.synchronize do
                output_print
                puts SRV_MSG
                puts "SERVER CONNECTIONS> #{@num_clients} ."
            end
            sleep 0.4
        end
    }
    begin
        srv = TCPServer.open(port)
    rescue Exception => e
        puts "failed to init srv: #{e.message}"
    end 
    return srv, t
end

def output_append(k, v)
    @ctl_msg[k] = v
end

def output_remove(k)
    @ctl_msg.delete(k)
end

def output_print
    @ctl_msg.each {|k, v| puts v}
end

#main
STDOUT.sync = true

if ARGV.count > 1
    puts "Proper usage: ./server.rb [listening_port]"
    exit
elsif ARGV.empty?
    port = default_port
else
    port = ARGV[0]
    ARGV.clear
end

server, t_id = init_srv(port)
puts t_id

loop {
    
    Thread.start(server.accept) do |c|
        sock_domain, remote_port, 
            remote_hostname, @remote_ip = c.peeraddr
        client_num = 0

        @mutex.synchronize do
            @num_clients += 1
            client_num = @num_clients
        end
        client = c.peeraddr[3]
        output_append("#{client} #{client_num}", "#{client} #{client_num} is connected")
        begin
            loop do
                line = c.readline
                #puts "#{client} #{client_num} says: #{line}"
                c.puts(line)
            end
        rescue EOFError
            c.close
            @mutex.synchronize do
                @num_clients -= 1
            end
            output_remove("#{client} #{client_num}")
        end    

    end
}

