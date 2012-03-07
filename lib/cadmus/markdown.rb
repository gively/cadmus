require 'redcarpet'
require 'cadmus/renderers'

module Cadmus
  module Markdown
    class HtmlRenderer < Redcarpet::Render::HTML
      include Redcarpet::Render::SmartyPants
    end
    
    class TextRenderer < Redcarpet::Render::Base
      def normal_text(text)
        text
      end
      
      def block_code(text, language)
        normal_text(text)
      end
      
      def codespan(text)
        normal_text(text)
      end
      
      def header(title, level)
        case level
        when 1
          "#{title.upcase}\n#{'=' * title.length}\n\n"
        when 2
          "#{title}\n#{'-' * title.length}\n\n"
        when 3
          "#{title.upcase}\n\n"
        end
      end
      
      def double_emphasis(text)
        "**#{text}**"
      end
      
      def emphasis(text)
        "*#{text}*"
      end
      
      def linebreak
        "\n"
      end
      
      def paragraph(text)
        "#{text}\n\n"
      end
      
      def list(content, list_type)
        "#{content}\n"
      end
      
      def list_item(content, list_type)
        "  * #{content}"
      end
    end
  end
  
  module Renderers
    class Markdown < Base
      attr_accessor :markdown_options
      
      def initialize
        super
        @markdown_options = {}
      end
      
      def markdown_options=(opts)
        @markdown_options = opts
        @redcarpet_instance = nil
      end
      
      def preprocess(template, format, options={})
        redcarpet_instance.render(super)
      end
      
      private
      def markdown_renderer(format)
        case format.to_sym
        when :html
          Cadmus::Markdown.HtmlRenderer
        when :text
          Cadmus::Markdown.TextRenderer
        else
          raise "Format #{format.inspect} is not supported by #{self.class.name}"
        end
      end
      
      def redcarpet_instance(format)
        Redcarpet::Markdown.new(markdown_renderer(format), markdown_options)
      end
    end
  end
  
  module MarkdownRenderable
    include Renderable
    
    def setup_renderer
      super
      renderer.markdown_options = markdown_options if respond_to?(:markdown_options)
    end
    
    def cadmus_renderer_class
      Cadmus::Renderers::Markdown
    end
  end
end