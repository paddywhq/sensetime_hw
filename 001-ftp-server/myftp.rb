require 'optparse'
require 'logger'
require 'socket'

#initialize in cmd
$options = {}

$options[:PORT] = 21
$options[:HOST] = '127.0.0.1'
$options[:DIR] = 'C:\\'
$options[:CLIENT_DIR] = {}
$options[:FILEPORT] = 20000

option_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: 001-ftp-server/myftp.rb [options]'

  opts.on('-p', "--port=PORT", "listen port") do |value|
    $options[:PORT] = value
  end

  opts.on("--host=HOST", "binding address") do |value|
    $options[:HOST] = value
  end

  opts.on("--dir=DIR", "change current directory") do |value|
    $options[:DIR] = value
  end

  opts.on('-h', 'print help') do
    puts opts
    exit
  end
end.parse!

#user&password
$user_pass = {
  'anonymous' => "",
  'paddywhq' => '10011110101001',
  'a' => 'a'
}

#response message
$response = {
  125 => "125 Data connection already open; transfer starting.\r\n",
  150 => "150 File status okay; about to open data connection.",
  200 => "200 Type set to I.\r\n",
  220 => "220 Service ready for new user.\r\n",
  226 => "226 Closing data connection.\r\n",
  227 => "227 Entering Passive Mode (#{$options[:HOST].gsub('.', ',')},#{$options[:FILEPORT]/256},#{$options[:FILEPORT]%256}).\r\n",
  230 => "230 User logged in, proceed.\r\n",
  250 => "250 Requested file action okay, completed.\r\n",
  257 => "257 \"#{$options[:DIR]}\" created.\r\n",
  331 => "331 User name okay, need password.\r\n",
  500 => "500 Syntax error, command unrecognized.\r\n",
  501 => "501 Syntax error in parameters or arguments.\r\n",
  530 => "530 Log in failed.\r\n",
  550 => "550 Requested action not taken.\r\n"
}

#log
$log = Logger.new('logfile.log')
$log.level = Logger::DEBUG

#PASS
def pass_command(user_name, command, client)
  $log.info(client + ': ' + command)

  password = command.chomp[5..(command.length - 1)]
  if $user_pass[user_name] == password
    client.puts $response[230]
    return true
  else
    client.puts $response[530]
    return false
  end
end

#USER
def user_command(command, client)
  $log.info(client + ': ' + command)

  user_name = command.chomp[5..(command.length - 1)]
  if $user_pass.has_key?(user_name)
    client.puts $response[331]
    loop do
      command = client.gets
      case
      when command.start_with?("PASS")
        return pass_command(user_name, command, client)
      else
        command_not_found(command, client)
      end
    end
  else
    client.puts $response[530]
    return false
  end
end

#LIST
def list_command(command, client)
  $log.info(client + ': ' + command)

  file_server = TCPServer.new($options[:HOST], $options[:FILEPORT])
  client.puts $response[150]
  file_client = file_server.accept

  Dir.foreach($options[:CLIENT_DIR][client]) {
    |file_name|
    file_info = (File.directory?($options[:CLIENT_DIR][client] + file_name) ? 'd' : '-')
    3.times {file_info += ((File.readable?($options[:CLIENT_DIR][client] + file_name) ? 'r' : '-') + (File.writable?($options[:CLIENT_DIR][client] + file_name) ? 'w' : '-') + (File.executable?($options[:CLIENT_DIR][client] + file_name) ? 'x' : '-'))}
    file_info += ' 1 0 0 '
    file_info += (File::size($options[:CLIENT_DIR][client] + file_name).to_s + ' ')
    file_info += (File::mtime($options[:CLIENT_DIR][client] + file_name).strftime('%b %d %H:%M ').to_s)
    file_info += file_name
    file_client.puts file_info
  }

  file_client.close
  file_server.close
  client.puts $response[226]
end

#CWD
def cwd_command(command, client)
  $log.info(client + ': ' + command)

  directory = command.chomp[4..(command.length - 1)]
  if(directory == "..\\" || directory == "..")
    if($options[:CLIENT_DIR][client].split("\\").length > 1)
      array = $options[:CLIENT_DIR][client].split("\\")
      array.pop
      $options[:CLIENT_DIR][client] = array.join("\\")
      $options[:CLIENT_DIR][client] += "\\" unless $options[:CLIENT_DIR][client].end_with?("\\")
      client.puts $response[250]
    else
      client.puts $response[550]
    end
  elsif (directory[1] == ":")
    if(File.exist?(directory) && File.directory?(directory))
      $options[:CLIENT_DIR][client] = directory
      $options[:CLIENT_DIR][client] += "\\" unless $options[:CLIENT_DIR][client].end_with?("\\")
      client.puts $response[250]
    else
      client.puts $response[550]
    end
  else
    if(File.exist?($options[:CLIENT_DIR][client] + directory) && File.directory?($options[:CLIENT_DIR][client] + directory))
      $options[:CLIENT_DIR][client] = $options[:CLIENT_DIR][client] + directory
      $options[:CLIENT_DIR][client] += "\\" unless $options[:CLIENT_DIR][client].end_with?("\\")
      client.puts $response[250]
    else
      client.puts $response[550]
    end
  end
end

#PWD
def pwd_command(command, client)
  $log.info(client + ': ' + command)

  $response[257] = "257 \"#{$options[:CLIENT_DIR][client]}\" created.\r\n"
  client.puts $response[257]
end

#RETR
def retr_command(command, client)
  $log.info(client + ': ' + command)

  file_name = command.chomp[5..(command.length - 1)]
  if File.exist?($options[:CLIENT_DIR][client] + file_name)
    file_server = TCPServer.new($options[:HOST], $options[:FILEPORT])
    client.puts $response[150]
    file_client = file_server.accept

    file = File.open($options[:CLIENT_DIR][client] + file_name, "rb")
    file.each { |line| file_client.puts line }
    file.close

    file_client.close
    file_server.close
    client.puts $response[226]
  else
    client.puts $response[550]
  end
end

#STOR
def stor_command(command, client)
  $log.info(client + ': ' + command)

  file_name = command.chomp[5..(command.length - 1)]

  file_server = TCPServer.new($options[:HOST], $options[:FILEPORT])
  client.puts $response[150]
  file_client = file_server.accept

  file = File.new($options[:CLIENT_DIR][client] + file_name, "wb")
  loop do
    line = file_client.gets
    break if line == nil
    file.print line
  end
  file.close

  file_client.close
  file_server.close
  client.puts $response[226]
end

#PASV
def pasv_command(command, client)
  $log.info(client + ': ' + command)

  $options[:FILEPORT] = ($options[:FILEPORT] + 1 - 20000) % 40000 + 20000
  $response[227] = "227 Entering Passive Mode (#{$options[:HOST].gsub('.', ',')},#{$options[:FILEPORT]/256},#{$options[:FILEPORT]%256}).\r\n"
  client.puts $response[227]
end

#TYPE
def type_command(command, client)
  $log.info(client + ': ' + command)
  type = command.chomp[5..(command.length - 1)]
  if(type == "I")
    $response[200] = "200 Type set to #{type}.\r\n"
    client.puts $response[200]
  elsif(type == "A")
    $response[200] = "200 Type set to #{type}.\r\n"
    client.puts $response[200]
  else
    client.puts $response[501]
  end
end

#not found
def command_not_found(command, client)
  $log.debug(client + ': ' + command)

  client.puts $response[500]
end

#start server
$server = TCPServer.new($options[:HOST], $options[:PORT])
loop do
  Thread.start($server.accept) do |client|
    $options[:CLIENT_DIR][client] = $options[:DIR]
    client.puts $response[220]
    loop do
      command = client.gets
      case
      when command.start_with?("USER")
        if user_command(command, client)
          break
        end
      else
        command_not_found(command, client)
      end
    end

    loop do
      command = client.gets.chomp
      case
      when command.start_with?("LIST")
        list_command(command, client)
      when command.start_with?("CWD")
        cwd_command(command, client)
      when command.start_with?("PWD")
        pwd_command(command, client)
      when command.start_with?("RETR")
        retr_command(command, client)
      when command.start_with?("STOR")
        stor_command(command, client)
      when command.start_with?("PASV")
        pasv_command(command, client)
      when command.start_with?("TYPE")
        type_command(command, client)
      else
        command_not_found(command, client)
      end
    end

    client.close
  end
end