module Cadmus

  # A controller mixin that includes all the RESTful resource actions for viewing and administering Cadmus
  # pages.  This mixin provides a great deal of flexibility for customizing the behavior of the resulting
  # controller.
  #
  # Controllers that include this mixin are expected to define at least a page_class method, which returns
  # the class to be used for pages in this context.
  #
  # == Examples
  #
  # A basic PagesController for a site:
  #
  #    class PagesController < ApplicationController
  #      include Cadmus::PagesController
  #
  #      # no action methods are necessary because PagesController defines them for us
  #
  #      protected
  #      def page_class
  #        Page
  #      end
  #      # Page must be defined as a model that includes Cadmus::Page
  #
  #    end
  #
  # A PagesController using CanCan for authorization control:
  #
  #    class PagesController < ApplicationController
  #      include Cadmus::PagesController
  #
  #      # no need for load_resource because PagesController does that for us
  #      authorize_resource :page
  #
  #      protected
  #      def page_class
  #        Page
  #      end
  #    end
  #
  # A controller for pages inside a Book object.  This controller uses URLs of the form
  # +/books/:book_id/pages/...+  The book_id parameter is a slug, not an ID.  First, here's
  # the Book model:
  #
  #    class Book < ActiveRecord::Base
  #      # This association has to be called "pages" because that's what BookPagesController
  #      # will expect to use to find them.
  #      has_many :pages, :class_name => "BookPage"
  #
  #      validates_uniqueness_of :slug
  #    end
  #
  #    class BookPagesController < ApplicationController
  #      include Cadmus::PagesController
  #
  #      self.page_parent_class = Book   # pages must have a Book as their parent
  #      self.page_parent_name = "book"  # use params[:book_id] for finding Books
  #      self.find_parent_by = "slug"    # use the Book's slug field for finding Books
  #
  #      protected
  #      def page_class
  #        BookPage
  #      end
  #    end
  module PagesController
    extend ActiveSupport::Concern
    include Cadmus::Renderable
    include Cadmus::Concerns::ControllerWithParent

    included do
      before_action :load_parent_and_page
      helper_method :cadmus_renderer
    end

    def index
      @pages = page_scope.order(:name).all

      respond_to do |format|
        format.html { render 'cadmus/pages/index' }
        format.xml  { render :xml => @pages }
        format.json { render :json => @pages }
      end
    end

    def show
      respond_to do |format|
        format.html { render 'cadmus/pages/show' }
        format.xml  { render :xml => @page }
        format.json { render :json => @page }
      end
    end

    def new
      @page = page_scope.new

      respond_to do |format|
        format.html { render 'cadmus/pages/new' }
        format.xml  { render :xml => @page }
        format.json { render :json => @page }
      end
    end

    def edit
      render 'cadmus/pages/edit'
    end

    def create
      @page = page_scope.new(page_params)

      respond_to do |format|
        if @page.save
          dest = { :action => 'show', :page_glob => @page.slug }
          format.html { redirect_to(dest, :notice => 'Page was successfully created.') }
          format.xml  { render :xml => @page, :status => :created, :location => dest }
          format.json { render :json => @page, :status => :created, :location => dest }
        else
          format.html { render 'cadmus/pages/new' }
          format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
          format.json { render :json => @page.errors, :status => :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @page.update_attributes(page_params)
          dest = { :action => 'show', :page_glob => @page.slug }
          format.html { redirect_to(dest, :notice => 'Page was successfully updated.') }
          format.xml  { head :ok }
          format.json { head :ok }
        else
          format.html { render 'cadmus/pages/edit' }
          format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
          format.json { render :json => @page.errors, :status => :unprocessable_entity }
        end
      end
    end

    def destroy
      @page.destroy

      respond_to do |format|
        format.html { redirect_to(:action => :index) }
        format.xml  { head :ok }
        format.json { head :ok }
      end
    end

    protected

    # Returns the ActiveRecord::Relation that will be used for finding pages.  If there is a page parent
    # for this request, this will be the "pages" scope defined by the parent object.  If there isn't,
    # this will be the "global" scope of the page class (i.e. pages with no parent object).
    def page_scope
      @page_scope ||= parent_model ? parent_model.pages : page_class.global
    end

    def page_class
      Cadmus.page_model
    end

    def page_params
      params.require(:page).permit(:name, :slug, :content)
    end

    def load_parent_and_page
      if params[:page_glob]
        @page = page_scope.find_by_slug(params[:page_glob])
        raise ActiveRecord::RecordNotFound.new("No page called #{params[:page_glob]}") unless @page
      end
    end

    def liquid_registers
      registers = { 'parent' => parent_model, :file_system => liquid_file_system }

      if defined?(super)
        registers.merge(super)
      else
        registers
      end
    end
  end
end
