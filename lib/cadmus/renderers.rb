module Cadmus
  module Renderers
    class Base
      attr_accessor :markdown_options, :markdown_renderer, :radius_context_stack
      
      def preprocess(content, *args)
        return content unless @radius_context_stack
        @radius_context_stack.process(content, *args)
      end
      
      def render(content, *args)
        redcarpet_instance.render(preprocess(content, *args))
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
    
    private
    def setup_renderer(renderer)
      renderer.markdown_options = markdown_options
      renderer.radius_context_stack = radius_context_stack
    end
  end
end