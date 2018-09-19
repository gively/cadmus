module Cadmus
  module Concerns
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

        def validates_template_validity(field_name)
          validate do |model|
            content = model.send(field_name)

            begin
              Liquid::Template.parse(content)
            rescue Exception => exception
              model.errors.add(field_name, "failed to parse: #{exception.class.name}: #{exception.message}")
            end
          end
        end
      end
    end
  end
end
