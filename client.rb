#!/usr/bin/ruby
# Chris Wood - A00741285 - COMP8005 - Assignment 2
# chriswood.ca@gmail.com
#
#

require 'socket'
require 'curses'

#default port
default_port = 8005
localhost = "127.0.0.1"
p_socket, c_socket = UNIXSocket.pair

def update_ui(msg)
	# width = msg.length + 6
	# win = Curses::Window.new(5, width,
	#         (Curses.lines - 5) / 2, (Curses.cols - width) / 2)
	# win.box(?|, ?-)
	# win.setpos(2, 3)
	# win.addstr(msg)
	# win.refresh
	# win.close
	Curses.setpos (0,0)
	Curses.addstr(msg)
	Curses.refresh
end

def init_ui
	Curses.noecho
	Curses.init_screen
end

if ARGV.empty? || ARGV.count > 3
	puts "Proper usage: ./client.rb server_addr [server_port] [numClients]"
	exit
elsif ARGV.count == 1
	srv = ARGV[0]
	port = default_port
	numClients = 1
elsif ARGV.count == 2
	srv = ARGV[0]
	port = ARGV[1]
	numClients = 1
elsif ARV.count == 3
	srv = ARGV[0]
	port = ARGV[1]
	numClients = ARGV[2]			
end

ARGV.clear


processes = (1..numClients).map do |p|
	Process.fork do
		begin
			#s = TCPSocket.open(srv.chomp, port)
			p_socket.close
			x = 1
			loop {
			#	s.puts "hello world from #{Process.pid}"
				c_socket.send "#{x}", 0
				x += 1
				sleep 3
			}
		rescue
			#socket error
		ensure
			#s.close
		end
	end
end

init_ui


x = 1
while 1
	#c_socket.close
	#from_child = p_socket.recv(100)
	update_ui "x is equal to: #{x}"
	x+=1
	#break if cmd.eql? "stop"
	sleep 1
end

processes.each {|p| Process.wait p} 




Curses.close_screen
