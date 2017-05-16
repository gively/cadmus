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

    included do
      class << self
        attr_accessor :page_parent_name, :page_parent_class, :find_parent_by
      end

      before_action :load_parent_and_page
      helper_method :cadmus_renderer
      helper_method :liquid_assigns_for_layout
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

    # This gets kind of meta.
    #
    # If page_parent_name and page_parent_class are both defined for this class, this method uses it to find
    # the parent object in which pages live.  For example, if page_parent_class is Blog and page_parent_name
    # is "blog", then this is equivalent to calling:
    #
    #     @page_parent = Blog.where(:id => params["blog_id"]).first
    #
    # If you don't want to use :id to find the parent object, then redefine the find_parent_by method to return
    # what you want to use.
    def page_parent
      return @page_parent if @page_parent

      if page_parent_name && page_parent_class
        parent_id_param = "#{page_parent_name}_id"
        if params[parent_id_param]
          @page_parent = page_parent_class.where(find_parent_by => params[parent_id_param]).first
        end
      end

      @page_parent
    end

    # Returns the name of the page parent object.  This will be used for determining the parameter name for
    # finding the parent object.  For example, if the page parent name is "wiki", the finder will look in
    # params["wiki_id"] to determine the object ID.
    #
    # By default, this will return the value of page_parent_name set at the controller class level, but can
    # be overridden for cases where the page parent name must be determined on a per-request basis.
    def page_parent_name
      self.class.page_parent_name
    end

    # Returns the class of the page parent object.  For example, if the pages used by this controller are
    # children of a Section object, this method should return the Section class.
    #
    # By default, this will return the value of page_parent_class set at the controller class level, but can
    # be overridden for cases where the page parent class must be determined on a per-request basis.
    def page_parent_class
      self.class.page_parent_class
    end

    # Returns the field used to find the page parent object.  By default this is :id, but if you need to
    # find the page parent object using a different parameter (for example, if you use a "slug" field for
    # part of the URL), this can be changed.
    #
    # By default this method takes its value from the "find_parent_by" accessor set at the controller class
    # level, but it can be overridden for cases where the finder field name should be determined on a
    # per-request basis.
    def find_parent_by
      self.class.find_parent_by || :id
    end

    # Returns the ActiveRecord::Relation that will be used for finding pages.  If there is a page parent
    # for this request, this will be the "pages" scope defined by the parent object.  If there isn't,
    # this will be the "global" scope of the page class (i.e. pages with no parent object).
    def page_scope
      @page_scope ||= page_parent ? page_parent.pages : page_class.global
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
      registers = { 'parent' => page_parent }

      if defined?(super)
        registers.merge(super)
      else
        registers
      end
    end

    def liquid_assigns_for_layout(cms_layout)
      {}
    end
  end
end