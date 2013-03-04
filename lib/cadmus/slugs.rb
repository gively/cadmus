module Cadmus
  module Slugs
    
    # Tests whether a string is a valid Cadmus slug or not.  A valid Cadmus slug
    # consists of one or more valid slug parts separated by forward slashes.  A valid
    # slug part consists of a lower-case letter followed by any combination of lower-case letters,
    # digits, and hyphens.
    #
    # For example, +about-us/people+, +special-deals+, and +winter-2012+ are all valid slugs, but
    # +3-things+, +123+, +nobody-lives-here!+, and +/root-page+ aren't.
    SLUG_REGEX = /\A([a-z][a-z0-9\-]*\/)*[a-z][a-z0-9\-]*\z/
  
    # Converts a string to a valid slug part by changing all whitespace to hyphens, converting all
    # upper-case letters to lower-case, removing all remaining non-alphanumeric, non-hyphen
    # characters, and removing any non-alphabetical characters at the beginning of the string.
    #
    # For example:
    # * "Katniss Everdeen" becomes "katniss-everdeen"
    # * "21 guns" becomes "guns"
    # * "We love you, Conrad!!!1" becomes "we-love-you-conrad1"
    def self.slugify(string)
      string.to_s.downcase.gsub(/\s+/, '-').gsub(/[^a-z0-9\-]/, '').sub(/\A[^a-z]+/, '')
    end
    
    # An extension for ActiveRecord::Base that adds a +has_slug+ method.  This can also be
    # safely included in non-ActiveRecord objects to allow for a similar method, but those
    # objects have to at least include ActiveModel::Validations.
    module HasSlug
      extend ActiveSupport::Concern
      
      module ClassMethods
        
        # Sets up an automatic slug-generating field on this class.  There is a slug field,
        # which will store the resulting slug, and a slug generator field, which, if set,
        # will automatically generate a slugified version of its content and store it in
        # the slug field.
        #
        # Additionally, +has_slug+ sets up a format validator for the slug field to ensure
        # that it's a valid Cadmus slug, and defines +to_param+ to return the slug (so
        # that links to the slugged object can use the slug in their URL).
        #
        # +has_slug+ attempts to be smart about detecting when the user has manually set a
        # slug for the object and not overwriting it.  Auto-generated slugs are only used
        # when there is not already a slug set.
        #
        # @param [Hash] options options to override the default behavior.
        # @option options slug_field the name of the slug field.  Defaults to +:slug+.
        # @option options slug_generator_field the name of the slug generator field.  Defaults
        #   to +:name+.
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