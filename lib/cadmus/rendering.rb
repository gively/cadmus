module Cadmus
  module Rendering
    module Common
      protected
      def render_content_with_renderer(renderer_name, content, options={})
        opts = options.dup.with_indifferent_access
        radius_context_stack = opts.delete(:radius_context_stack)
        
        content = radius_context_stack.process(content) if radius_context_stack
        
        send("#{renderer_name}_renderer", opts).render(content)
      end
    end
    
    module Html
      include Cadmus::Rendering::Common
      
      def html_renderer(options={})
        Redcarpet::Markdown.new(Cadmus::Markdown::HtmlRenderer, options)
      end
      
      def render_html(content, options={})
        render_content_with_renderer(:html, content, options).html_safe
      end
    end
    
    module Text  
      include Cadmus::Rendering::Common
    
      def text_renderer(options={})
        Redcarpet::Markdown.new(Cadmus::Markdown::TextRenderer, options)
      end
  
      def render_text(content, options={})
        rendered_content = render_content_with_renderer(:text, content, options)
        sanitizer.sanitize(rendered_content)
      end
      
      private
      def sanitizer
        Rails.application.config.action_view.full_sanitizer || HTML::FullSanitizer.new
      end
    end
    
    module Renderable
      extend ActiveSupport::Concern
      
      included do
        include Cadmus::Rendering::Html
        include Cadmus::Rendering::Text
      end
      
      module ClassMethods
        def cadmus_renderable(content_fields, options={}, &block)
          cattr_accessor :default_markdown_options, :content_fields, :radius_context_stack, :prerender_block
          self.default_markdown_options = options[:markdown_options] || {}
          self.radius_context_stack = options[:radius_context_stack]
          self.prerender_block = block
          
          self.content_fields = case content_fields
          when nil
            []
          when Array
            content_fields
          else
            [content_fields.to_s]
          end
          
          self.content_fields.each do |field|
            class_eval <<-EOF
            def html_#{field}(*args)
              render_html(self.#{field}, rendering_options(args))
            end
            
            def text_#{field}(*args)
              render_text(self.#{field}, rendering_options(args))
            end
            EOF
          end
          
          class_eval do
            def rendering_options(args)
              opts = default_markdown_options.dup
              opts.update(:radius_context_stack => radius_context_stack)
              opts.update(instance_exec(*args, &prerender_block))
            end
          end
        end
      end
    end
  end
end


ActiveRecord::Base.send :include, Cadmus::Rendering::Renderable