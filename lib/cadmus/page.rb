module Cadmus

  # Adds a +cadmus_page+ extension method to ActiveRecord::Base that sets up a class as a page-like object for
  # Cadmus.
  module Page
    extend ActiveSupport::Concern
    include Cadmus::Concerns::LiquidTemplateField
    include Cadmus::Concerns::ModelWithParent

    module ClassMethods

      # Sets up a model to behave as a Cadmus page.  This will add the following behaviors:
      #
      # * A slug and slug generator field using HasSlug
      # * A name field that determines the name of the page for administrative UI
      # * An optional, polymorphic +parent+ field
      # * A scope called +global+ that returns instances of this class that have no parent
      # * A +liquid_template+ method that parses the value of this model's +content+ field as a Liquid
      #   template
      # * Validators that ensure that this page has a name, that this page's slug is unique within the
      #   parent object, and that the slug isn't "pages" or "edit" (which are used for admin UI)
      #
      # @param options [Hash] options to modify the default behavior
      # @option options :name_field the name of the field to be used as the page name.  Defaults to +:name+.
      # @option options :slug_field the name of the field to be used as the page slug.  Defaults to +:slug+.
      # @option options :slug_generator_field the name of the field to be used as the slug generator.
      #   Defaults to the value of +name_field+ if unspecified.
      # @option options :layout_model_name the name of the model to use as a layout for this page class.
      def cadmus_page(options={})
        options[:slug_generator_field] = options[:name_field] unless options.has_key?(:slug_generator_field)
        has_slug(options)

        cattr_accessor :name_field
        self.name_field = (options.delete(:name_field) || :name).to_s

        model_with_parent

        validates_presence_of name_field
        validates_uniqueness_of slug_field, :scope => [:parent_id, :parent_type]
        validates_exclusion_of slug_field, :in => %w(pages edit)

        cattr_accessor :layout_model_name
        self.layout_model_name = options.delete(:layout_model_name) || Cadmus.layout_model.try!(:name)

        if layout_model
          belongs_to :cms_layout, class_name: layout_model.name, optional: true
        end

        liquid_template_field :liquid_template, :content
      end

      def layout_model
        return unless layout_model_name
        layout_model_name.safe_constantize
      end
    end

    def effective_cms_layout
      return nil unless respond_to?(:cms_layout)
      cms_layout
    end
  end
end