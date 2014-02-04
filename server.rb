#!/usr/bin/ruby
# Chris Wood - A00741285 - COMP8005 - Assignment 2
# chriswood.ca@gmail.com
#
#server

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
        		s.puts($_)
        	end
        }    
        client.close
    end
}





#Curses.close_screen

