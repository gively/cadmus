module Cadmus
  module Slugs
    SLUG_REGEX = /^([a-z][a-z0-9\-]*\/)*[a-z][a-z0-9\-]*$/
  
    def self.slugify(string)
      string.to_s.downcase.gsub(/\s/, '-').gsub(/[^a-z0-9\-]/, '')
    end
    
    module HasSlug
      extend ActiveSupport::Concern
  
      included do
      end
      
      module ClassMethods
        def has_slug(options={})
          cattr_accessor :slug_field, :slug_generator_field
          
          self.slug_field = (options.delete(:slug_field) || :slug).to_s
          self.slug_generator_field = (options.delete(:slug_generator_field) || :name).to_s
          
          validates_format_of slug_field, :with => Cadmus::Slugs::SLUG_REGEX
          
          class_eval <<-EOF
          def #{slug_generator_field}=(new_value)
            write_attribute(:#{slug_generator_field}, new_value)
            if #{slug_field}.blank?
              self.#{slug_field} = Cadmus::Slugs.slugify(new_value)
              @auto_assigned_slug = true
            end
          end
          
          # If the user enters a title and no slug, don't overwrite the auto-assigned one
          def #{slug_field}=(new_slug)
            return if new_slug.blank? && @auto_assigned_slug
            write_attribute(:#{slug_field}, new_slug)
          end
          
          def to_param
            #{slug_field}
          end
          EOF
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Cadmus::Slugs::HasSlug