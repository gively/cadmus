module Cadmus
  module LayoutsController
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :cms_layout_parent_name, :cms_layout_parent_class, :find_parent_by
      end

      before_action :load_parent_and_cms_layout
    end

    def index
      @cms_layouts = cms_layout_scope.order(cms_layout_scope.klass.name_field).all
      render 'cadmus/layouts/index'
    end

    def new
      @cms_layout = cms_layout_scope.new
      render 'cadmus/layouts/new'
    end

    def edit
      render 'cadmus/layouts/edit'
    end

    def create
      @cms_layout = cms_layout.new(cms_layout_params)

      if @cms_layout.save
        redirect_to(url_for(action: 'index'))
      else
        render 'cadmus/layouts/new'
      end
    end

    def update
      if @cms_layout.update_attributes(cms_layout_params)
        redirect_to(url_for(action: 'index'))
      else
        render 'cadmus/layouts/edit'
      end
    end

    def destroy
      @cms_layout.destroy
      redirect_to(url_for(action: 'index'))
    end

    protected

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
    def cms_layout_parent
      return @cms_layout_parent if @cms_layout_parent

      if cms_layout_parent_name && cms_layout_parent_class
        parent_id_param = "#{cms_layout_parent_name}_id"
        if params[parent_id_param]
          @cms_layout_parent = cms_layout_parent_class.find_by(find_parent_by => params[parent_id_param])
        end
      end

      @cms_layout_parent
    end

    # Returns the name of the layout parent object.  This will be used for determining the parameter name for
    # finding the parent object.  For example, if the parent name is "wiki", the finder will look in
    # params["wiki_id"] to determine the object ID.
    #
    # By default, this will return the value of cms_layout_parent_name set at the controller class level, but can
    # be overridden for cases where the layout parent name must be determined on a per-request basis.
    def cms_layout_parent_name
      self.class.cms_layout_parent_name
    end

    # Returns the class of the layout parent object.  For example, if the pages used by this controller are
    # children of a Section object, this method should return the Section class.
    #
    # By default, this will return the value of cms_layout_parent_class set at the controller class level, but can
    # be overridden for cases where the layout parent class must be determined on a per-request basis.
    def cms_layout_parent_class
      self.class.cms_layout_parent_class
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

    # Returns the ActiveRecord::Relation that will be used for finding layouts.  If there is a parent
    # for this request, this will be the "cms_layouts" scope defined by the parent object.  If there isn't,
    # this will be the "global" scope of the layout class (i.e. layouts with no parent object).
    def cms_layout_scope
      @cms_layout_scope ||= cms_layout_parent ? cms_layout_parent.cms_layouts : cms_layout_class.global
    end

    def cms_layout_params
      params.require(:cms_layout).permit(:name, :content)
    end

    def load_parent_and_cms_layout
      if params[:id]
        @cms_layout = cms_layout_scope.find(params[:id])
      end
    end
  end
end