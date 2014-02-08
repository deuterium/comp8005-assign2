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
default_port, @num_clients, @mutex = 8005, 0, Mutex.new
STDOUT.sync = true

#functions
def init_srv(port)
    #
    t = Thread.new {
        while 1
            system "clear"
            @mutex.synchronize do
                puts "SERVER CONNECTIONS> #{@num_clients}"
            end
            sleep 0.4
            system "clear"
            @mutex.synchronize do
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


#Curses.noecho
#Curses.init_screen

=begin
Socket.tcp_server_loop(port) do |conn, addr|
    puts "SERVER CONNECTIONS> #{num_clients}"
    Thread.new do
        @mutex.synchronize do
            num_clients += 1
        end
        client = "#{addr.ip_address}:#{addr.ip_port}"
        puts "#{client} is connected"
        begin
            loop do
                line = conn.readline
                puts "#{client} says: #{line}"
                conn.puts(line)
            end
        rescue EOFError
            conn.close
            puts "#{client} has disconnected"
            @mutex.synchronize do
                num_clients -= 1
            end
        end
    end
end
=end

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
            #update_ui 0, num_clients
        end
        #puts "SERVER CONNECTIONS2> #{num_clients}"
        #client = "#{addr.ip_address}:#{addr.ip_port}"
        client = c.peeraddr[3]
        #puts "#{client} is connected"
        begin
            loop do
                line = c.readline
                #puts "#{client} #{client_num} says: #{line}"
                c.puts(line)
            end
        rescue EOFError
            c.close
            #puts "#{client} #{client_num} has disconnected"
            @mutex.synchronize do
                @num_clients -= 1
            end
        end    

    end
}

#Curses.close_screen

