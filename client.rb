#!/usr/bin/env ruby
=begin
-------------------------------------------------------------------------------------
--  SOURCE FILE:    client.rb - A multi-threaded echo client
--
--  PROGRAM:        client 
--                ./client.rb server_addr [server_port] [numClients]
--
--  FUNCTIONS:      Ruby Socket & Thread Classes
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
--  The program will establish a TCP connection to a user specifed server.
--  The server can be specified using a fully qualified domain name or and
--  IP address. By default, the program will create 1 thread. The user can 
--  specify the number of threads to run. After the connection has been 
--  established, each thread will send a string to the server 5 times and 
--  the response (echo) back from the server is displayed.
--  This client application can be used to test the accompanying servers:
--  server_mt.rb (multithreaded)
--  server_select.rb (select)
--  server_epoll.rb (epoll)
---------------------------------------------------------------------------------------
=end

require 'socket'
require 'thread'
require 'time'

# default port for program
default_port = 8005
# String constants
LOG_NAME = "client_log"
# variable locks
@lock, @lock2 = Mutex.new, Mutex.new
# data structures
@data = Hash.new

## Functions
# Returns the server's time
# * *Returns* :
#   - the system time (format YYYY-MM-DD HH:MM:SS)
#
def time
	t = Time.now
	return t.strftime("%Y-%m-%d %H:%M:%S")
end

# Returns the server's time
# * *Returns* :
#   - the system time (format HH-MM-SS)
#
def time2
	t = Time.now
	return t.strftime("%H-%M-%S")
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
        @lock.synchronize do 
            File.open(LOG_NAME, 'a') { |f| f.write ("#{time},#{msg}") }
        end
    rescue Exception => e
        # problem opening or writing to file
        print_exception(e)
    end
end

# Adds a message with a key to the data dictionary.
# Used for storing incoming and outgoing connections.
# * *Args*    :
#   - +k+ -> key to store data under
#   - +v+ -> data to store
#
def data_add(k, v)
	@lock2.synchronize do 
        if @data[k] == nil # does not exist
            @data[k] = v
        else               # exists
            @data[k] += v
        end
    end
end

## Main
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

# clear for STDIN, if applicable
ARGV.clear

# send 3-15 messages
num_messages = rand(3..15)

threads = (1..numClients.to_i).map do |t|
	Thread.new(t) do |t|
		begin
			puts "#{time} T#:#{t} ID:#{Thread.current} created"
			# connect to server, create socket
			s = TCPSocket.open(srv.chomp, port)
		rescue Exception => e
			# error with server connection
			print_exception(e)
			exit!
		end
		begin
			(1..num_messages).each do |i|
				msg = "hello world from #{Thread.current}: #{i}"
				data_add("#{Thread.current}-#{i}", "out,#{time},#{msg.bytesize},")
				s.puts msg
				resp = s.readline
				data_add("#{Thread.current}-#{i}", "in,#{time}")
				puts "SERVER REPLY> #{resp}"
				sleep(rand(1..3))
			end
		rescue Exception => e
			# error sending or receiving message from server
			print_exception(e)
		ensure
			# ensure socket closes
			s.close
			puts "#{time} T#:#{t} ID:#{Thread.current} ended"
		end
	end
end

# wait for threads to finish, no zombies
threads.each {|t| t.join}


@data.each {
	|k,v|
	temp = v.split(',')
	diff = Time.parse(temp[3]) - Time.parse(temp[1])
	puts "#{k}\t#{v}\tRTT: #{diff}sec"
	File.open("#{LOG_NAME}#{time2}", 'a') { |f| f.write ("#{k}\t#{v}\tRTT: #{diff}sec") }
}
