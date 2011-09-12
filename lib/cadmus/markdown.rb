require 'redcarpet'

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
end