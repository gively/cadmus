require 'redcarpet'
require 'cadmus/renderers'

module Cadmus
  module Markdown
    # A Redcarpet renderer that outputs HTML and uses SmartyPants smart
    # quotes.
    class HtmlRenderer < Redcarpet::Render::HTML
      include Redcarpet::Render::SmartyPants
    end
    
    # A Redcarpet renderer that outputs formatted plain text (that looks quite similar to
    # the Markdown input sent to it).
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
    
    # A Cadmus renderer that handles Markdown input using the Redcarpet rendering engine.
    # It can produce +:html+ and +:text+ formats, using Cadmus::Markdown::HtmlRenderer
    # and Cadmus::Markdown::TextRenderer.
    #
    # Liquid is rendered first, then the result is processed as Markdown.
    class Markdown < Base
      
      # Additional options to be passed as the second argument to the Redcarpet::Markdown
      # constructor.
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
  
  # An alternative to Cadmus::Renderable that will use Cadmus::Renderers::Markdown as the
  # renderer class.  Additionally, it will set the renderer's +markdown_options+ to the
  # return value of the +markdown_options+ method, if that method is defined.
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