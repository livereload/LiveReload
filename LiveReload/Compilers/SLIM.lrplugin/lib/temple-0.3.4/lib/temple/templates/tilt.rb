require 'tilt'

module Temple
  module Templates
    class Tilt < ::Tilt::Template
      extend Mixins::Template

      # Prepare Temple template
      #
      # Called immediately after template data is loaded.
      #
      # @return [void]
      def prepare
        @src = self.class.build_engine({ :streaming => false, # Overwrite option: No streaming support in Tilt
                                         :file => eval_file }, options).call(data)
      end

      # A string containing the (Ruby) source code for the template.
      #
      # @param [Hash]   locals Local variables
      # @return [String] Compiled template ruby code
      def precompiled_template(locals = {})
        @src
      end

      def self.register_as(name)
        ::Tilt.register name.to_s, self
      end
    end
  end
end
