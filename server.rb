require 'socket'
require 'json'
require_relative 'mttp'

server = TCPServer.open 2000

def generate_next(message)
  mhttp = MHTTPMessage.new(message)  
  
  type = mhttp.msg[:type]
  start_line = mhttp.msg[:startline]
  request_body = mhttp.msg[:body]
  params = JSON.parse(request_body)
  return nil unless type == :request

  method = start_line[:method]
  target = start_line[:target]

  path = File.join('public_html', target)

  case method 
  when "GET"
    if File.exist? path 
      file_str = File.open(path).read
      return generate_message_by_code(200, file_str)
    else
      return generate_message_by_code(404, "")
    end
  when "POST"
    if File.exist? path
      file_str = File.open(path).read
      file_str.gsub!(/\n\s*<%=\s*yield\s*%>/, yielder(params))
      return generate_message_by_code(200, file_str)
    else
      return generate_message_by_code(404, "")
    end
  else
    return nil
  end
end

def yielder(params)
  result = ""
  params["pirate"].each do |key, value|
    result = result + "\n    <li>#{key}: #{value}</li>"
  end
  return result
end

def generate_message_by_code(code, body)
  cf = "\r\n"
  header = "Host: localhost"
  phrase = {200 => "OK", 404 => "Not Found"}

  case code
  when 200
    contents = body
  when 404
    contents = "AAARRR!!! Treasure not found!!"
  else
    return nil
  end

  return "HTTP/1.1 #{code} #{phrase[code]}\r\n#{header}\r\n\r\n#{contents}"
end 

loop do
    socket = server.accept

    message = socket.recvmsg[0]
    print "Received message:\n#{message}\n\n"

    response = generate_next(message)

    socket.puts response unless response.nil?
    socket.close
end
