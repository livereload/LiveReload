module Temple
  module Mixins
    # @api private
    module CoreDispatcher
      def on_multi(*exps)
        multi = [:multi]
        exps.each {|exp| multi << compile(exp) }
        multi
      end

      def on_capture(name, exp)
        [:capture, name, compile(exp)]
      end
    end

    # @api private
    module EscapeDispatcher
      def on_escape(flag, exp)
        [:escape, flag, compile(exp)]
      end
    end

    # @api private
    module ControlFlowDispatcher
      def on_if(condition, *cases)
        [:if, condition, *cases.compact.map {|e| compile(e) }]
      end

      def on_case(arg, *cases)
        [:case, arg, *cases.map {|condition, exp| [condition, compile(exp)] }]
      end

      def on_block(code, content)
        [:block, code, compile(content)]
      end

      def on_cond(*cases)
        [:cond, *cases.map {|condition, exp| [condition, compile(exp)] }]
      end
    end

    # @api private
    module CompiledDispatcher
      def call(exp)
        compile(exp)
      end

      def compile(exp)
        dispatcher(exp)
      end

      private

      def case_statement(types)
        code = "type, *args = args\ncase type\n"
        types.each do |name, method|
          code << "when #{name.to_sym.inspect}\n" <<
            (Hash === method ? case_statement(method) : "#{method}(*args)\n")
        end
        code << "else\nexp\nend\n"
      end

      def dispatcher(exp)
        replace_dispatcher(exp)
      end

      def replace_dispatcher(exp)
        types = {}
        self.class.instance_methods.each do |method|
          next if method.to_s !~ /^on_(.*)$/
          method_types = $1.split('_')
          (0...method_types.size).inject(types) do |tmp, i|
            raise "Invalid temple dispatcher #{method}" unless Hash === tmp
            if i == method_types.size - 1
              tmp[method_types[i]] = method
            else
              tmp[method_types[i]] ||= {}
            end
          end
        end
        self.class.class_eval %{
          def dispatcher(exp)
            if self.class == #{self.class}
              args = exp
              #{case_statement(types)}
            else
              replace_dispatcher(exp)
            end
          end
        }
        dispatcher(exp)
      end
    end

    # @api private
    module Dispatcher
      include CompiledDispatcher
      include CoreDispatcher
      include EscapeDispatcher
      include ControlFlowDispatcher
    end
  end
end
