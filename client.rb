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

#default port
default_port = 8005
localhost = "127.0.0.1"
p_socket, c_socket = UNIXSocket.pair


#functions


#main
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
elsif ARGV.count == 3
	srv = ARGV[0]
	port = ARGV[1]
	numClients = ARGV[2]
end

ARGV.clear

threads = (1..numClients.to_i).map do |t|
	Thread.new(t) do |t|
		begin
			puts "#{Thread.current} created"
			begin
			s = TCPSocket.open(srv.chomp, port)
		rescue Exception => e
			puts e.message
		end
			(1..5).each do |i|
				s.puts "hello world from #{Thread.current}: #{i}"
				#c_socket.send("#{p}: #{x}", 0)
				puts "ECHO REPLY> #{s.readline}"
				sleep 1.5
			end
		rescue Exception => e
			puts "error: #{e.message}"
		ensure
			s.close
		end
	end
end

#wait for threads to finish, no zombies
threads.each {|t| t.join}


