module Temple
  module Mixins
    # @api private
    module Template
      include DefaultOptions

      def engine(engine = nil)
        default_options[:engine] = engine if engine
        default_options[:engine]
      end

      def build_engine(*options)
        raise 'No engine configured' unless engine
        options << default_options
        engine.new(ImmutableHash.new(*options))
      end

      def chain(&block)
        chain = (default_options[:chain] ||= [])
        chain << block if block
        chain
      end
    end
  end
end
