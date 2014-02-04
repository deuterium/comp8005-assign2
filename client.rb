#!/usr/bin/ruby
# Chris Wood - A00741285 - COMP8005 - Assignment 2
# chriswood.ca@gmail.com
#
#

require 'socket'

#default port
default_port = 8005
localhost = "127.0.0.1"

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
