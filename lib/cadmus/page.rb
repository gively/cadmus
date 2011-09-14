module Cadmus
  module Page
    extend ActiveSupport::Concern
    
    module ClassMethods
      def cadmus_page(options={})
        options[:slug_generator_field] = options[:name_field] unless options.has_key?(:slug_generator_field)
        has_slug(options)

        cattr_accessor :name_field
        self.name_field = (options.delete(:name_field) || :name).to_s

        belongs_to :parent, :polymorphic => true
                
        validates_presence_of name_field
        validates_uniqueness_of slug_field, :within => [:parent_id, :parent_type]
        validates_exclusion_of slug_field, :in => %w(pages edit)
  
        scope :global, :conditions => { :parent_id => nil, :parent_type => nil }
      end      
    end
  end
end

ActiveRecord::Base.send :include, Cadmus::Page