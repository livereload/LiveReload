module Temple
  # Exception raised if invalid temple expression is found
  #
  # @api public
  class InvalidExpression < RuntimeError
  end

  # Abstract generator base class
  # Generators should inherit this class and
  # compile the Core Abstraction to ruby code.
  #
  # @api public
  class Generator
    include Mixins::Options

    default_options[:buffer] = '_buf'

    def call(exp)
      [preamble, compile(exp), postamble].join('; ')
    end

    def compile(exp)
      type, *args = exp
      method = "on_#{type}"
      if respond_to?(method)
        send(method, *args)
      else
        raise InvalidExpression, "Generator supports only core expressions - found #{exp.inspect}"
      end
    end

    def on_multi(*exp)
      exp.map {|e| compile(e) }.join('; ')
    end

    def on_newline
      "\n"
    end

    def on_capture(name, exp)
      options[:capture_generator].new(:buffer => name).call(exp)
    end

    def on_static(text)
      concat(text.inspect)
    end

    def on_dynamic(code)
      concat(code)
    end

    def on_code(code)
      code
    end

    protected

    def buffer
      options[:buffer]
    end

    def concat(str)
      "#{buffer} << (#{str})"
    end
  end

  module Generators
    # Implements an array buffer.
    #
    #   _buf = []
    #   _buf << "static"
    #   _buf << dynamic
    #   _buf.join
    #
    # @api public
    class Array < Generator
      def preamble
        "#{buffer} = []"
      end

      def postamble
        buffer
      end
    end

    # Just like Array, but calls #join on the array.
    # @api public
    class ArrayBuffer < Array
      def postamble
        "#{buffer} = #{buffer}.join"
      end
    end

    # Implements a string buffer.
    #
    #   _buf = ''
    #   _buf << "static"
    #   _buf << dynamic.to_s
    #   _buf
    #
    # @api public
    class StringBuffer < Array
      def preamble
        "#{buffer} = ''"
      end

      def on_dynamic(code)
        concat("(#{code}).to_s")
      end
    end

    # Implements a rails output buffer.
    #
    #   @output_buffer = ActionView::OutputBuffer
    #   @output_buffer.safe_concat "static"
    #   @output_buffer.safe_concat dynamic.to_s
    #   @output_buffer
    #
    # @api public
    class RailsOutputBuffer < StringBuffer
      set_default_options :buffer_class => 'ActiveSupport::SafeBuffer',
                          :buffer => '@output_buffer',
                           # output_buffer is needed for Rails 3.1 Streaming support
                          :capture_generator => RailsOutputBuffer

      def preamble
        if options[:streaming] && options[:buffer] == '@output_buffer'
          "#{buffer} = output_buffer || #{options[:buffer_class]}.new"
        else
          "#{buffer} = #{options[:buffer_class]}.new"
        end
      end

      def concat(str)
        "#{buffer}.safe_concat((#{str}))"
      end
    end
  end

  Generator.default_options[:capture_generator] = Temple::Generators::StringBuffer
end
