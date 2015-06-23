module PList
  class << self
    def get file_name, key
      if File.read(file_name) =~ %r!<key>#{Regexp.escape(key)}</key>\s*<string>(.*?)</string>!
        $1.strip
      else
        nil
      end
    end
    def set file_name, key, value
      text = File.read(file_name).gsub(%r!(<key>#{Regexp.escape(key)}</key>\s*<string>).*?(</string>)!) {
        "#{$1}#{value}#{$2}"
      }
      File.open(file_name, 'w') { |f| f.write text }
    end
  end
end
