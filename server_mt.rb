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
--                  none
--
--
--  DESIGNERS:      Chris Wood - chriswood.ca@gmail.com
--
--  PROGRAMMERS:    Chris Wood - chriswood.ca@gmail.com
--
--  NOTES:
--  The program will establish a TCP connection to a user specifed server.
--  The server can be specified using a fully qualified domain name or and
--  IP address. After the connection has been established the user will be
--  prompted for date. The date string is then sent to the server and the
--  response (echo) back from the server is displayed.
--  This client application can be used to test the aaccompanying epoll
--  server: epoll_svr.c
---------------------------------------------------------------------------------------
=end

require 'socket'

#default port, initial clients, thread mutex
SRV_MSG = "^^ Server Output ^^"
default_port, @num_clients, @mutex = 8005, 0, Mutex.new
STDOUT.sync = true
#@ctl_msg = Array.new(["Server Output:"])
@ctl_msg = Hash.new

#functions
#Returns the system time (format YYYY-MM-DD HH:MM:SS)
def time
    t = Time.now
    return t.strftime("%Y-%m-%d %H:%M:%S")
end

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

