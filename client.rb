#!/usr/bin/ruby
=begin
-------------------------------------------------------------------------------------
--  SOURCE FILE:    client.rb - A multi-threaded echo client
--
--  PROGRAM:        client 
--                ./client.rb server_addr [server_port] [numClients]
--
--  FUNCTIONS:      Berkeley Socket API
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

#default port for program
default_port = 8005

##functions
#Returns the system time (format YYYY-MM-DD HH:MM:SS)
def time
	t = Time.now
	return t.strftime("%Y-%m-%d %H:%M:%S")
end

##main
if ARGV.empty? || ARGV.count > 3
	puts "Proper usage: ./client.rb server_addr [server_port] [numClients]"
	exit
elsif ARGV.count == 1 #custom srv + default port + 1 client
	srv = ARGV[0]
	port = default_port
	numClients = 1
elsif ARGV.count == 2 #custom srv/port + 1 client
	srv = ARGV[0]
	port = ARGV[1]
	numClients = 1
elsif ARGV.count == 3 #custom srv/port/# of clients
	srv = ARGV[0]
	port = ARGV[1]
	numClients = ARGV[2]
end

#clear for STDIN, if applicable
ARGV.clear

threads = (1..numClients.to_i).map do |t|
	Thread.new(t) do |t|
		begin
			puts "#{time} T#:#{t} ID:#{Thread.current} created"
			begin
			s = TCPSocket.open(srv.chomp, port)
		rescue Exception => e
			puts e.message
		end
			(1..5).each do |i|
				s.puts "hello world from #{Thread.current}: #{i}"
				puts "SERVER REPLY> #{s.readline}"
				sleep(rand(1..3))
			end
		rescue Exception => e
			puts "error: #{e.message}"
		ensure
			s.close
			puts "#{time} T#:#{t} ID:#{Thread.current} ended"
		end
	end
end

#wait for threads to finish, no zombies
threads.each {|t| t.join}
