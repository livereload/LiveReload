module Temple
  module Mixins
    # @api public
    module DefaultOptions
      def set_default_options(options)
        default_options.update(options)
      end

      def default_options
        @default_options ||= MutableHash.new(superclass.respond_to?(:default_options) ?
                                             superclass.default_options : nil)
      end
    end

    # @api public
    module Options
      def self.included(base)
        base.class_eval { extend DefaultOptions }
      end

      attr_reader :options

      def initialize(options = {})
        @options = ImmutableHash.new(options, self.class.default_options)
      end
    end
  end
end
