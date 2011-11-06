is_green = (File.read('test.css') rescue '') =~ /\bgreen\b/

File.open 'test.css', 'w' do |f|
    orig = File.read('test-orig.css')
    orig.gsub! /\bgreen\b/, 'red' if is_green
    sleep 0.2
    f.puts 'body { background: maroon; }'
    sleep 0.2
    f.write orig
end
