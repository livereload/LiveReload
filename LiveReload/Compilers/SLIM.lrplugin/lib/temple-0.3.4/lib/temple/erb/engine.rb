module Temple
  module ERB
    # Example ERB engine implementation
    #
    # @api public
    class Engine < Temple::Engine
      use Temple::ERB::Parser
      use Temple::ERB::Trimming, :trim_mode
      filter :Escapable, :use_html_safe, :disable_escape
      filter :MultiFlattener
      filter :DynamicInliner
      generator :ArrayBuffer
    end
  end
end
