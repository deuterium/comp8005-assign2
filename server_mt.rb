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
require 'curses'

#default port
default_port = 8005
p_socket, c_socket = UNIXSocket.pair
BUFF_LEN = 10


#functions
def update_ui(msg)
	# width = msg.length + 6
	# win = Curses::Window.new(5, width,
	#         (Curses.lines - 5) / 2, (Curses.cols - width) / 2)
	# win.box(?|, ?-)
	# win.setpos(2, 3)
	# win.addstr(msg)
	# win.refresh
	# win.close
	Curses.setpos(0,0)
	Curses.addstr(msg)
	Curses.refresh
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

server = TCPServer.open(port)
loop {
	puts "before accept"
    Thread.start(server.accept) do |client|
    	puts "after accept"
        sock_domain, remote_port, 
            remote_hostname, @remote_ip = client.peeraddr

        loop {
        	while client.gets
        		puts($_)
        	end
        }    
        client.close
    end
}





#Curses.close_screen

