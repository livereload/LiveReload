module Temple
  # @api public
  module Utils
    extend self

    # Returns an escaped copy of `html`.
    # Strings which are declared as html_safe are not escaped.
    #
    # @param html [String] The string to escape
    # @return [String] The escaped string
    def escape_html_safe(html)
      html.html_safe? ? html : escape_html(html)
    end

    if defined?(EscapeUtils)
      # Returns an escaped copy of `html`.
      #
      # @param html [String] The string to escape
      # @return [String] The escaped string
      def escape_html(html)
        EscapeUtils.escape_html(html.to_s)
      end
    elsif RUBY_VERSION > '1.9'
      # Used by escape_html
      # @api private
      ESCAPE_HTML = {
        '&' => '&amp;',
        '"' => '&quot;',
        '<' => '&lt;',
        '>' => '&gt;',
        '/' => '&#47;',
      }.freeze

      # Returns an escaped copy of `html`.
      #
      # @param html [String] The string to escape
      # @return [String] The escaped string
      def escape_html(html)
        html.to_s.gsub(/[&\"<>\/]/, ESCAPE_HTML)
      end
    else
      # Returns an escaped copy of `html`.
      #
      # @param html [String] The string to escape
      # @return [String] The escaped string
      def escape_html(html)
        html.to_s.gsub(/&/n, '&amp;').gsub(/\"/n, '&quot;').gsub(/>/n, '&gt;').gsub(/</n, '&lt;').gsub(/\//, '&#47;')
      end
    end

    # Generate unique variable name
    #
    # @param prefix [String] Variable name prefix
    # @return [String] Variable name
    def unique_name(prefix = nil)
      @unique_name ||= 0
      prefix ||= (@unique_prefix ||= self.class.name.gsub('::', '_').downcase)
      "_#{prefix}#{@unique_name += 1}"
    end

    # Check if expression is empty
    #
    # @param exp [Array] Temple expression
    # @return true if expression is empty
    def empty_exp?(exp)
      case exp[0]
      when :multi
        exp[1..-1].all? {|e| empty_exp?(e) }
      when :newline
        true
      else
        false
      end
    end
  end
end
