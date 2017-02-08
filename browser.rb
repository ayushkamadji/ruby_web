require 'socket'
require 'json'
require_relative 'mttp'

exit_command = false

def parse(url)
  host = url.scan(/\A.+(?=:)/).flatten[0]
  port = url.scan(/(?<=:).+(?=\/)/).flatten[0].to_i
  path = url.scan(/\/.+(?=$)/).flatten[0]
  
  return [host, port, path]
end

def browse(host, port, path, met, data)
  sockc = TCPSocket.open(host, port)
  message = "#{met} #{path} HTTP/1.1\r\nHost:#{host}\r\nContent-Length: #{data.length}\r\n\r\n"
  message = message + data if met == "POST"
  sockc.sendmsg message

  mttp = MHTTPMessage.new(sockc.recvmsg[0])
  type = mttp.msg[:type]
  start_line = mttp.msg[:startline]
  body = mttp.msg[:body]

  unless type == :response
    puts ""
    gets
    return nil
  end
  
  case start_line[:code]
  when 200 then page = body
  when 404 then page = "404 Not Found\n#{body}"
  end

  print page
  gets
end
  
def start_form
  print "\e[2J\e[1;1H"
  puts "For Kraken's sake join us already!"
  print "Name: "
  name = gets.strip
  print "Email: "
  email = gets.strip
  return {pirate: {name: name, email: email}}
end

def print_help
  print "\e[2J\e[1;1H"
  puts "\"exit\"\t\t- exit the browser"
  puts "\"help\"\t\t- show this help"
  puts "\"submit\"\t- start pirate registartion"
  gets
end

until exit_command
  print "\e[2J\e[1;1H"
  puts "Type in url (i.e. \"localhost:2000/path\") or \"help\" for help"
  input = gets.strip
  print "\n"

  case input
  when 'exit'
    exit_command = true
    break
  when 'help'
    print_help
    next
  when 'submit'
    data = start_form().to_json
    browse(*parse("localhost:2000/thanks.html"), "POST",data)
    next
  end

  browse(*parse(input), "GET", "")
end

