module Cadmus
  module Concerns
    module ModelWithParent
      extend ActiveSupport::Concern

      module ClassMethods
        def model_with_parent
          belongs_to :parent, polymorphic: true, optional: true
          scope :global, -> { where(:parent_id => nil, :parent_type => nil) }
        end
      end
    end
  end
end
