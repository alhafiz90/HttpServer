require 'socket'
class Webserver
  def process_request(session, base_path)
    session.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
    request = session.gets
    puts request
    request_file = request.gsub(/GET\ \//, '').gsub(/POST\ \//, '').gsub(/\ HTTP.*/i, '').gsub(/GET/, '').strip
    #request_file = request.gsub(/HTTP.*/, '').gsub(/(GET|POST).*\/\/.*\//, '').strip
    puts request_file
    filename=request_file.chomp
    if filename == ""
      filepath = base_path+"index.html"
      puts "filepath:#{filepath}"
    else
      filepath = base_path+filename
      puts " filepath: #{filepath}"
    end
    begin
      displayfile = File.open(filepath, 'r')
      content = displayfile.read()
      session.print content
    rescue Errno::ENOENT
      session.print "File not found"
    end
    session.close
  end
end
class RequestHandler
  def initialize(server, port, base_path)
    @server=server
    @port=port
    @base_path=base_path
    @httpserver = TCPServer.new(@server, @port)

  end

  def handle_client
    loop do
      @session=@httpserver.accept
      Thread.start(@session, @base_path) do |session, base_path|
        puts "#{session.peeraddr[2]} (#{session.peeraddr[3]})\n"
        puts "processing..."
        Webserver.new.process_request(session, base_path)
      end
    end
  end
end
     handler= RequestHandler.new("127.0.0.1", 7200, "/home/abdullah.hafiz/All_Ruby_Project/Webserver/")
handler.handle_client
