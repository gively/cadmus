module Cadmus
  module Tags
    class PageUrl < ::Liquid::Tag
      class << self
        attr_reader :page_path_method

        def define_page_path_method(&page_path_method)
          @page_path_method = page_path_method
        end
      end

      attr_reader :page_name

      def initialize(tag_name, args, tokens)
        super
        @page_name = args.strip.gsub(/\A['"](.*)['"]\z/, '$1')
      end

      def render(context)
        unless self.class.page_path_method
          return "Error: #{self.class.name}.page_path_method is not defined.  Please call #{self.class.name}.define_page_path_method in an initializer."
        end

        begin
          parent = context.registers['parent']
          Rails.application.routes.url_helpers.instance_exec(page_name, parent, &self.class.page_path_method)
        rescue Exception => e
          e.message
        end
      end
    end
  end
end

Liquid::Template.register_tag('page_url', Cadmus::Tags::PageUrl)
