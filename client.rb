#!/usr/bin/ruby
# Chris Wood - A00741285 - COMP8005 - Assignment 2
# chriswood.ca@gmail.com
#
#

require 'socket'
require 'curses'
require 'pry'

#default port
default_port = 8005
localhost = "127.0.0.1"
Curses.noecho
Curses.init_screen

def report(txt)
	Curses.setpos(1,0)
	Curses.addstr(txt)
	Curses.refresh
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
			puts "starting process"
			#s = TCPSocket.open(srv.chomp, port)
			x = 1
			loop {
			#	s.puts "hello world from #{Process.pid}"
			binding.pry
				puts x+1
				report(1)
			}
		rescue
			#socket error
		ensure
			#s.close
		end
	end
end
processes.each {|p| Process.wait p} 
while cmd = gets.chomp
	break if cmd.eql? "stop"
end




Curses.close_screen

