require 'date'
require 'cgi'

puts %Q<DELETE FROM stats;>

Dir['logs/*'].each do |file|
  File.read(file).each_line do |line|
    if line =~ /\[(\d+\/\w+\/\d{4}:\d+:\d+:\d+ \+\d+)\] (\d+\.\d+\.\d+\.\d+).*ping.txt\?v=([0-9.]+).*"([^"]+)" -$/
      time, ip, ver, ua = $1, $2, $3, CGI.unescape($4)
      time.sub! ':', ' '
      d = DateTime.parse(time).new_offset(0)
      utime = Time.gm(d.year, d.month, d.day, d.hour, d.min, d.sec).to_i
      date = d.strftime('%Y-%m-%d')
      raise "bad UA found!" if ua.include? '"'
      puts %Q<INSERT INTO stats(time, date, ip, version, agent) VALUES(#{utime}, FROM_UNIXTIME(#{utime}), "#{ip}", "#{ver}", "#{ua}");>
    end
  end
end
