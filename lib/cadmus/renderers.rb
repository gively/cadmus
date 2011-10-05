module Cadmus
  module Renderers
    class Base
      attr_accessor :markdown_options, :markdown_renderer, :default_assigns, :default_filters
      
      def preprocess(template, options={})
        options = options.with_indifferent_access        
        template.render(assigns(options[:assigns]), filters(options[:filters]))
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
      
      def assigns(passed_assigns=nil)
        (self.default_assigns || {}).merge(passed_assigns || {})
      end
      
      def filters(passed_filters=nil)
        (self.default_filters || []) + (passed_filters || [])
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
      renderer.default_assigns = (respond_to?(:liquid_assigns) ? liquid_assigns : {})
      renderer.default_filters = (respond_to?(:liquid_filters) ? liquid_filters : {})
    end
  end
end