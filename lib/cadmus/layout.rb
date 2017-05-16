module Cadmus
  module Layout
    extend ActiveSupport::Concern
    include Cadmus::LiquidTemplateField

    module ClassMethods
      # Sets up a model to behave as a Cadmus layout.  This will add the following behaviors:
      #
      # * A name field that determines the name of the layout for administrative UI
      # * An optional, polymorphic +parent+ field
      # * A scope called +global+ that returns instances of this class that have no parent
      # * A +liquid_template+ method that parses the value of this model's +content+ field as a Liquid
      #   template
      # * A validator that ensure that this layout has a name
      #
      # @param options [Hash] options to modify the default behavior
      # @option options :name_field the name of the field to be used as the layout name.  Defaults to +:name+.
      def cadmus_layout(options = {})
        belongs_to :parent, polymorphic: true
        scope :global, lambda { where(:parent_id => nil, :parent_type => nil) }

        cattr_accessor :name_field
        self.name_field = (options.delete(:name_field) || :name).to_s
        validates_uniqueness_of name_field, scope: [:parent_id, :parent_type]

        liquid_template_field :liquid_template, :content
      end
    end
  end
end