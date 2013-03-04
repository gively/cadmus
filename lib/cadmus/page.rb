require 'liquid'

module Cadmus
  
  # Adds a +cadmus_page+ extension method to ActiveRecord::Base that sets up a class as a page-like object for
  # Cadmus.
  module Page
    extend ActiveSupport::Concern
    
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
      def cadmus_page(options={})
        options[:slug_generator_field] = options[:name_field] unless options.has_key?(:slug_generator_field)
        has_slug(options)

        cattr_accessor :name_field
        self.name_field = (options.delete(:name_field) || :name).to_s

        belongs_to :parent, :polymorphic => true
                
        validates_presence_of name_field
        validates_uniqueness_of slug_field, :scope => [:parent_id, :parent_type]
        validates_exclusion_of slug_field, :in => %w(pages edit)
  
        scope :global, lambda { where(:parent_id => nil, :parent_type => nil) }
        
        class_eval do
          def liquid_template
            Liquid::Template.parse(content)
          end
        end
      end      
    end
  end
end

ActiveRecord::Base.send :include, Cadmus::Page