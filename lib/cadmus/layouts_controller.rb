module Cadmus
  module LayoutsController
    extend ActiveSupport::Concern
    include Cadmus::Concerns::ControllerWithParent

    included do
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

    # Returns the ActiveRecord::Relation that will be used for finding layouts.  If there is a parent
    # for this request, this will be the "cms_layouts" scope defined by the parent object.  If there isn't,
    # this will be the "global" scope of the layout class (i.e. layouts with no parent object).
    def cms_layout_scope
      @cms_layout_scope ||= parent_model ? parent_model.cms_layouts : cms_layout_model.global
    end

    def cms_layout_model
      Cadmus.layout_model
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