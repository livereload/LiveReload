module Temple
  module ERB
    # ERB trimming
    # Set option :trim_mode to
    #    <> - omit newline for lines starting with <% and ending in %>
    #    >  - omit newline for lines ending in %>
    #
    # @api public
    class Trimming < Filter
      def on_multi(*exps)
        case options[:trim_mode]
        when '>'
          exps.each_cons(2) do |a, b|
            if code?(a) && static?(b)
              b[1].gsub!(/^\n/, '')
            end
          end
        when '<>'
          exps.each_with_index do |exp, i|
            if code?(exp) &&
                (!exps[i-1] || static?(exps[i-1]) && exps[i-1][1] =~ /\n$/) &&
                (exps[i+1] && static?(exps[i+1]) && exps[i+1][1] =~ /^\n/)
              exps[i+1][1].gsub!(/^\n/, '') if exps[i+1]
            end
          end
        end
        [:multi, *exps]
      end

      protected

      def code?(exp)
        exp[0] == :escape || exp[0] == :code
      end

      def static?(exp)
        exp[0] == :static
      end
    end
  end
end
