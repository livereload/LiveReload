module Temple
  module Filters
    # Merges several statics into a single static.  Example:
    #
    #   [:multi,
    #     [:static, "Hello "],
    #     [:static, "World!"]]
    #
    # Compiles to:
    #
    #   [:multi,
    #     [:static, "Hello World!"]]
    #
    # @api public
    class StaticMerger < Filter
      def on_multi(*exps)
        result = [:multi]
        text = nil

        exps.each do |exp|
          if exp.first == :static
            if text
              text << exp.last
            else
              text = exp.last.dup
              result << [:static, text]
            end
          else
            result << compile(exp)
            text = nil unless exp.first == :newline
          end
        end

        result
      end
    end
  end
end
