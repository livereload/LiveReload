module Temple
  module HTML
    # @api public
    class Fast < Filter
      XHTML_DOCTYPES = {
        '1.1'          => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">',
        '5'            => '<!DOCTYPE html>',
        'html'         => '<!DOCTYPE html>',
        'strict'       => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
        'frameset'     => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
        'mobile'       => '<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">',
        'basic'        => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">',
        'transitional' => '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
      }.freeze

      HTML_DOCTYPES = {
        '5'            => '<!DOCTYPE html>',
        'html'         => '<!DOCTYPE html>',
        'strict'       => '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
        'frameset'     => '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
        'transitional' => '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">',
      }.freeze

      set_default_options :format => :xhtml,
                          :attr_wrapper => "'",
                          :autoclose => %w[meta img link br hr input area param col base]

      HTML = [:html, :html4, :html5]

      def initialize(opts = {})
        super
        unless [:xhtml, *HTML].include?(options[:format])
          raise "Invalid format #{options[:format].inspect}"
        end
      end

      def xhtml?
        options[:format] == :xhtml
      end

      def html?
        HTML.include?(options[:format])
      end

      def on_html_doctype(type)
        type = type.to_s
        trailing_newlines = type[/(\A|[^\r])(\n+)\Z/, 2].to_s
        text = type.downcase.strip

        if text =~ /^xml/
          raise 'Invalid xml directive in html mode' if html?
          wrapper = options[:attr_wrapper]
          str = "<?xml version=#{wrapper}1.0#{wrapper} encoding=#{wrapper}#{text.split(' ')[1] || "utf-8"}#{wrapper} ?>"
        elsif html?
          str = HTML_DOCTYPES[text] || raise("Invalid html doctype #{text}")
        else
          str = XHTML_DOCTYPES[text] || raise("Invalid xhtml doctype #{text}")
        end

        [:static, str << trailing_newlines]
      end

      def on_html_comment(content)
        [:multi,
          [:static, '<!--'],
          compile(content),
          [:static, '-->']]
      end

      def on_html_tag(name, attrs, content = nil)
        name = name.to_s
        closed = !content || (empty_exp?(content) && options[:autoclose].include?(name))
        result = [:multi, [:static, "<#{name}"], compile(attrs)]
        result << [:static, (closed && xhtml? ? ' /' : '') + '>']
        result << compile(content) if content
        result << [:static, "</#{name}>"] if !closed
        result
      end

      def on_html_attrs(*attrs)
        [:multi, *attrs.map {|attr| compile(attr) }]
      end

      def on_html_attr(name, value)
        [:multi,
         [:static, " #{name}=#{options[:attr_wrapper]}"],
         compile(value),
         [:static, options[:attr_wrapper]]]
      end
    end
  end
end
