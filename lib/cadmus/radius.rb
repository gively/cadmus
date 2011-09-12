require 'radius'

module Cadmus
  module Radius
    class ContextStack
      attr_reader :contexts
      
      def initialize(contexts={})
        @contexts = {}
        contexts.each do |namespace, context|
          add_context(namespace, context)
        end
      end
      
      def add_context(namespace, context)
        contexts[namespace.to_s] = context
      end
    
      def process(content)
        contexts.each do |namespace, context|
          effective_context = case context
          when ::Radius::Context
            context
          when Proc
            context.call
          end
          
          parser = ::Radius::Parser.new(effective_context, :tag_prefix => namespace.to_s)
          content = parser.parse(content)
        end
        content
      end
    end
  end
end