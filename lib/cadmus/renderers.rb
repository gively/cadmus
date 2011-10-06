module Cadmus
  module Renderers
    class Base
      attr_accessor :markdown_options, :markdown_renderer, :default_assigns, :default_filters, :default_registers
      
      def initialize
        self.default_registers = {}
        self.default_filters = []
        self.default_assigns = {}
      end
      
      def preprocess(template, options={}) 
        render_args = [
          default_assigns.merge(options[:assigns] || {}), 
          { 
            :filters   => default_filters + (options[:filters] || []),
            :registers => default_registers.merge(options[:registers] || {})
          }
        ]  
       
        template.render(*render_args)
      end
      
      def render(template, options={})
        redcarpet_instance.render(preprocess(template, options))
      end
      
      def markdown_options=(opts)
        @markdown_options = opts
        @redcarpet_instance = nil
      end
      
      def markdown_renderer=(renderer)
        @markdown_renderer = renderer
        @redcarpet_instance = nil
      end
      
      private
      def redcarpet_instance
        @redcarpet_instance ||= Redcarpet::Markdown.new(@markdown_renderer, @markdown_options)
      end
    end
    
    class Html < Base
      def initialize
        super
        self.markdown_renderer = Cadmus::Markdown::HtmlRenderer
      end
      
      def render(content, *args)
        super(content, *args).html_safe
      end
    end
        
    class Text < Base
      attr_accessor :sanitizer
      
      def initialize
        super
        self.markdown_renderer = Cadmus::Markdown::TextRenderer
        self.sanitizer = Rails.application.config.action_view.full_sanitizer || HTML::FullSanitizer.new
      end
  
      def render(content, *args)
        sanitizer.sanitize(super(content, *args))
      end
    end
  end
  
  module Renderable
    def html_renderer
      Cadmus::Renderers::Html.new.tap { |renderer| setup_renderer(renderer) }
    end

    def text_renderer
      Cadmus::Renderers::Text.new.tap { |renderer| setup_renderer(renderer) }
    end
    
    protected
    def setup_renderer(renderer)
      renderer.markdown_options = (respond_to?(:markdown_options) ? markdown_options : {})
      renderer.default_assigns = liquid_assigns if respond_to?(:liquid_assigns)
      renderer.default_registers = liquid_registers if respond_to?(:liquid_registers)
      renderer.default_filters = liquid_filters if respond_to?(:liquid_filters)
    end
  end
end