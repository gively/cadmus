module Cadmus
  module Partial
    extend ActiveSupport::Concern
    include Cadmus::Concerns::LiquidTemplateField
    include Cadmus::Concerns::ModelWithParent

    module ClassMethods
      # Sets up a model to behave as a Cadmus partial.  This will add the following behaviors:
      #
      # * A name field that determines the name of the partial for administrative UI
      # * An optional, polymorphic +parent+ field
      # * A scope called +global+ that returns instances of this class that have no parent
      # * A +liquid_template+ method that parses the value of this model's +content+ field as a Liquid
      #   template
      # * A validator that ensure that this layout has a name
      #
      # @param options [Hash] options to modify the default behavior
      # @option options :name_field the name of the field to be used as the layout name.  Defaults to +:name+.
      # @option options :skip_template_validation if present, skips the validation of the content template.
      def cadmus_partial(options = {})
        model_with_parent

        cattr_accessor :name_field
        self.name_field = (options.delete(:name_field) || :name).to_s
        validates_uniqueness_of name_field, scope: [:parent_id, :parent_type]

        liquid_template_field :liquid_template, :content
        validates_template_validity :content unless options[:skip_template_validation]
      end
    end
  end
end
