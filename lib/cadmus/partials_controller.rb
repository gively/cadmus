module Cadmus
  module PartialsController
    extend ActiveSupport::Concern
    include Cadmus::Concerns::ControllerWithParent

    included do
      before_action :load_parent_and_cms_partial
    end

    def index
      @cms_partials = cms_partial_scope.order(cms_partial_scope.klass.name_field).all
      render 'cadmus/partials/index'
    end

    def new
      @cms_partial = cms_partial_scope.new
      render 'cadmus/partials/new'
    end

    def edit
      render 'cadmus/partials/edit'
    end

    def create
      @cms_partial = cms_partial_scope.new(cms_partial_params)

      if @cms_partial.save
        redirect_to(url_for(action: 'index'))
      else
        render 'cadmus/partials/new'
      end
    end

    def update
      if @cms_partial.update_attributes(cms_partial_params)
        redirect_to(url_for(action: 'index'))
      else
        render 'cadmus/partials/edit'
      end
    end

    def destroy
      @cms_partial.destroy
      redirect_to(url_for(action: 'index'))
    end

    protected

    # Returns the ActiveRecord::Relation that will be used for finding partials.  If there is a parent
    # for this request, this will be the "cms_partials" scope defined by the parent object.  If there isn't,
    # this will be the "global" scope of the partial class (i.e. partials with no parent object).
    def cms_partial_scope
      @cms_partial_scope ||= parent_model ? parent_model.cms_partials : Cadmus.partial_model.global
    end

    def cms_partial_params
      params.require(:cms_partial).permit(Cadmus.partial_model.name_field, :content)
    end

    def load_parent_and_cms_partial
      if params[:id]
        @cms_partial = cms_partial_scope.find(params[:id])
      end
    end
  end
end