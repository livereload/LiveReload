module Temple
  module HTML
    # @api public
    class Pretty < Fast
      set_default_options :indent => '  ',
                          :pretty => true,
                          :indent_tags => %w(article aside audio base body datalist dd div dl dt
                                             fieldset figure footer form head h1 h2 h3 h4 h5 h6
                                             header hgroup hr html img input li link meta nav ol p
                                             rp rt ruby section script style table tbody td tfoot
                                             th thead title tr ul video).freeze,
                          :pre_tags => %w(code pre textarea).freeze

      def initialize(opts = {})
        super
        @last = :noindent
        @indent = 0
        @pretty = options[:pretty]
        @pre_tags = Regexp.new(options[:pre_tags].map {|t| "<#{t}" }.join('|'))
      end

      def call(exp)
        @pretty ? [:multi, preamble, compile(exp)] : super
      end

      def on_static(content)
        if @pretty
          content.gsub!("\n", indent) if @pre_tags !~ content
          @last = content.sub!(/\r?\n\s*$/, ' ') ? nil : :noindent
        end
        [:static, content]
      end

      def on_dynamic(code)
        if @pretty
          @last = :noindent
          tmp = unique_name
          gsub_code = if ''.respond_to?(:html_safe?)
                        "#{tmp} = #{tmp}.html_safe? ? #{tmp}.gsub(\"\\n\", #{indent.inspect}).html_safe : #{tmp}.gsub(\"\\n\", #{indent.inspect})"
                      else
                        "#{tmp}.gsub!(\"\\n\", #{indent.inspect})"
                      end
          [:multi,
           [:code, "#{tmp} = (#{code}).to_s"],
           [:code, "if #{@pre_tags_name} !~ #{tmp}; #{gsub_code}; end"],
           [:dynamic, tmp]]
        else
          [:dynamic, code]
        end
      end

      def on_html_doctype(type)
        @last = nil
        super
      end

      def on_html_comment(content)
        return super unless @pretty
        @last = nil
        [:multi, [:static, indent], super]
      end

      def on_html_tag(name, attrs, content = nil)
        return super unless @pretty

        name = name.to_s
        closed = !content || (empty_exp?(content) && options[:autoclose].include?(name))

        @pretty = false
        result = [:multi, [:static, "#{tag_indent(name)}<#{name}"], compile(attrs)]
        result << [:static, (closed && xhtml? ? ' /' : '') + '>']

        @pretty = !options[:pre_tags].include?(name)
        if content
          @indent += 1
          result << compile(content)
          @indent -= 1
        end

        result << [:static, "#{tag_indent(name)}</#{name}>"] if !closed
        @pretty = true
        result
      end

      protected

      def preamble
        @pre_tags_name = unique_name
        [:code, "#{@pre_tags_name} = /#{@pre_tags.source}/"]
      end

      # Return indentation if not in pre tag
      def indent
        "\n" + (options[:indent] || '') * @indent
      end

      # Return indentation before tag
      def tag_indent(name)
        result = @last != :noindent && (options[:indent_tags].include?(@last) || options[:indent_tags].include?(name)) ? indent : ''
        @last = name
        result
      end
    end
  end
end
