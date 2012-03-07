module Cadmus
  module Renderers
    class Base
      attr_accessor :default_assigns, :default_filters, :default_registers, :html_sanitizer
      
      def initialize
        self.default_registers = {}
        self.default_filters = []
        self.default_assigns = {}
        
        self.html_sanitizer = Rails.application.config.action_view.full_sanitizer || HTML::FullSanitizer.new
      end
      
      def preprocess(template, format, options={}) 
        render_args = [
          default_assigns.merge(options[:assigns] || {}), 
          { 
            :filters   => default_filters + (options[:filters] || []),
            :registers => default_registers.merge(options[:registers] || {})
          }
        ]  
       
        template.render(*render_args)
      end
      
      def render(template, format, options={})
        content = preprocess(template, format, options={})
        
        case format.to_sym
        when :html
          content.html_safe
        when :text
          html_sanitizer.sanitize content
        else
          raise "Format #{format.inspect} unsupported by #{self.class.name}"
        end
      end
    end
  end
  
  module Renderable
    def cadmus_renderer
      cadmus_renderer_class.new.tap { |renderer| setup_renderer(renderer) }
    end
    
    def cadmus_renderer_class
      Cadmus::Renderers::Base
    end
    
    protected
    def setup_renderer(renderer)
      renderer.default_assigns = liquid_assigns if respond_to?(:liquid_assigns)
      renderer.default_registers = liquid_registers if respond_to?(:liquid_registers)
      renderer.default_filters = liquid_filters if respond_to?(:liquid_filters)
    end
  end
end