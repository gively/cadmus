module Cadmus
  module Concerns
    module OtherClassAccessor
      # Defines an accessor method for a field that stores a class.  Simply storing the class can mess up Rails
      # reloading, so behind the scenes, this stores the name of the class and then, when something tries to get the
      # value of the field, safe_constantizes that name and memoizes the result.
      #
      # When using this in a gem, it's important to call the clear_<field name>_cache! method in the engine's
      # to_prepare block, e.g.:
      #
      #    config.to_prepare do
      #      Cadmus::PartialFileSystem.clear_partial_model_cache!
      #    end
      def other_class_accessor(field_name)
        name_ivar = "@_#{field_name}_name"
        class_memo_ivar = "@_#{field_name}"

        # getter method
        define_singleton_method field_name do
          memoized_class = instance_variable_get(class_memo_ivar)

          unless memoized_class
            name = instance_variable_get(name_ivar)
            return unless name

            memoized_class = name.safe_constantize
            instance_variable_set(class_memo_ivar, memoized_class)
          end

          memoized_class
        end

        # setter method
        define_singleton_method "#{field_name}=" do |klass|
          class_name = case klass
          when Class then klass.name
          else klass
          end

          instance_variable_set(name_ivar, class_name)
        end

        # clear memoized class method
        define_singleton_method "clear_#{field_name}_cache!" do
          instance_variable_set(class_memo_ivar, nil)
        end
      end
    end
  end
end
