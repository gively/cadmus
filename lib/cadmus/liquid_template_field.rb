module Cadmus
  module LiquidTemplateField
    extend ActiveSupport::Concern

    module ClassMethods
      def liquid_template_field(method_name, field_name)
        define_method method_name do
          content = send(field_name)

          begin
            Liquid::Template.parse(content)
          rescue Exception => exception
            Liquid::Template.parse("#{exception.class.name}: #{exception.message}")
          end
        end
      end
    end
  end
end