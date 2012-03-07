module Cadmus
	module PagesController
		extend ActiveSupport::Concern
		include Cadmus::Renderable
		
		included do
			class << self
				attr_accessor :page_parent_name, :page_parent_class, :find_parent_by
			end
			
			before_filter :load_parent_and_page
		  helper_method :html_renderer, :text_renderer
		end
	
		module InstanceMethods
		  # GET /pages
			# GET /pages.xml
			def index
				@pages = page_scope.order(:name).all
			
				respond_to do |format|
					format.html { render 'cadmus/pages/index' }
					format.xml  { render :xml => @pages }
				end
			end
		
			# GET /pages/1
			# GET /pages/1.xml
			def show
				respond_to do |format|
					format.html { render 'cadmus/pages/show' }
					format.xml  { render :xml => @page }
				end
			end
		
			# GET /pages/new
			# GET /pages/new.xml
			def new
				@page = page_scope.new(params[:page])
			
				respond_to do |format|
					format.html { render 'cadmus/pages/new' }
					format.xml  { render :xml => @page }
				end
			end
		
			# GET /pages/1/edit
			def edit			
				render 'cadmus/pages/edit'
			end
		
			# POST /pages
			# POST /pages.xml
			def create
				@page = page_scope.new(params[:page])
			
				respond_to do |format|
					if @page.save
						dest = { :action => 'show', :page_glob => @page.slug }
						format.html { redirect_to(dest, :notice => 'Page was successfully created.') }
						format.xml  { render :xml => @page, :status => :created, :location => dest }
					else
						format.html { render 'cadmus/pages/new' }
						format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
					end
				end
			end
		
			# PUT /pages/1
			# PUT /pages/1.xml
			def update
				respond_to do |format|
					if @page.update_attributes(params[:page])
						dest = { :action => 'show', :page_glob => @page.slug }
						format.html { redirect_to(dest, :notice => 'Page was successfully updated.') }
						format.xml  { head :ok }
					else
						format.html { render 'cadmus/pages/edit' }
						format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
					end
				end
			end
		
			# DELETE /pages/1
			# DELETE /pages/1.xml
			def destroy
				@page.destroy
		
				respond_to do |format|
					format.html { redirect_to(:action => :index) }
					format.xml  { head :ok }
				end
			end
			
			protected
      
      # This gets kind of meta.
      #
      # If page_parent_name and page_parent_class are both defined for this class, this method uses it to find
      # the parent object in which pages live.  For example, if page_parent_class is Blog and page_parent_name
      # is "blog", then this is equivalent to calling:
      #
      # @page_parent = Blog.where(:id => params["blog_id"]).first
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
			
			def page_parent_name
        self.class.page_parent_name
			end
			
			def page_parent_class
			  self.class.page_parent_class
			end
			
			def find_parent_by
				self.class.find_parent_by || :id
			end
			
			def page_scope
				@page_scope ||= page_parent ? page_parent.pages : page_class.global
			end
			
			def load_parent_and_page
				if params[:page_glob]
					@page = page_scope.find_by_slug(params[:page_glob]) if params[:page_glob]
					raise ActiveRecord::RecordNotFound.new("No page called #{params[:page_glob]}") unless @page
				end
			end
		end
	end
end