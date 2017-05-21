module Cadmus
  module Concerns
    module ControllerWithParent
      extend ActiveSupport::Concern

      included do
        class << self
          attr_accessor :parent_model_name, :parent_model_class, :find_parent_by
        end
      end

      # This gets kind of meta.
      #
      # If cms_layout_parent_name and cms_layout_parent_class are both defined for this class, this method uses it to find
      # the parent object in which layouts live.  For example, if cms_layout_parent_class is Blog and
      # cms_layout_parent_name is "blog", then this is equivalent to calling:
      #
      #     @cms_layout_parent = Blog.where(:id => params["blog_id"]).first
      #
      # If you don't want to use :id to find the parent object, then redefine the find_parent_by method to return
      # what you want to use.
      def parent_model
        return @parent_model if @parent_model

        if parent_model_name && parent_model_class
          parent_id_param = "#{parent_model_name}_id"
          if params[parent_id_param]
            @parent_model = parent_model_class.find_by(find_parent_by => params[parent_id_param])
          end
        end

        @parent_model
      end

      # Returns the name of the layout parent object.  This will be used for determining the parameter name for
      # finding the parent object.  For example, if the parent name is "wiki", the finder will look in
      # params["wiki_id"] to determine the object ID.
      #
      # By default, this will return the value of cms_layout_parent_name set at the controller class level, but can
      # be overridden for cases where the layout parent name must be determined on a per-request basis.
      def parent_model_name
        self.class.parent_model_name
      end

      # Returns the class of the layout parent object.  For example, if the pages used by this controller are
      # children of a Section object, this method should return the Section class.
      #
      # By default, this will return the value of cms_layout_parent_class set at the controller class level, but can
      # be overridden for cases where the layout parent class must be determined on a per-request basis.
      def parent_model_class
        self.class.parent_model_class
      end

      # Returns the field used to find the layout parent object.  By default this is :id, but if you need to
      # find the layout parent object using a different parameter (for example, if you use a "slug" field for
      # part of the URL), this can be changed.
      #
      # By default this method takes its value from the "find_parent_by" accessor set at the controller class
      # level, but it can be overridden for cases where the finder field name should be determined on a
      # per-request basis.
      def find_parent_by
        self.class.find_parent_by || :id
      end
    end
  end
end