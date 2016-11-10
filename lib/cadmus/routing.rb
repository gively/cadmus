module Cadmus
  # A routing constraint that determines whether a request has a valid Cadmus page glob.  A
  # page glob consists of one or more valid slug parts separated by forward slashes.  A valid
  # slug part consists of a lower-case letter followed by any combination of lower-case letters,
  # digits, and hyphens.
  class SlugConstraint
    # @param request an HTTP request object.
    # @return [Boolean] true if this request's +:page_glob+ parameter is a valid Cadmus page
    #   glob, false if it's not.  Allows +:page_glob+ to be nil only if the Rails environment
    #   is +test+, because +assert_recognizes+ doesn't always pass the full params hash
    #   including globbed parameters.
    def matches?(request)
      page_glob = request.path_parameters.symbolize_keys[:page_glob]

      # assert_recognizes doesn't pass the full params hash as we would in a real Rails
      # application.  So we have to always pass this constraint if we're testing.
      return true if page_glob.nil? && Rails.env.test?

      page_glob.sub(/\A\//, '').split(/\//).all? do |part|
        part =~ /\A[a-z][a-z0-9\-]*\z/
      end
    end
  end
end

ActionDispatch::Routing::Mapper.class_eval do
  # Defines a "cadmus_pages" DSL command you can use in config/routes.rb.  This sets up a Cadmus
  # PagesController that will accept the following routes:
  #
  # * GET /pages -> PagesController#index
  # * GET /pages/new -> PagesController#new
  # * POST /pages -> PagesController#create
  # * GET /pages/anything/possibly-including/slashes/edit -> PagesController#edit
  # * GET /pages/anything/possibly-including/slashes -> PagesController#show
  # * PUT /pages/anything/possibly-including/slashes -> PagesController#update
  # * DELETE /pages/anything/possibly-including/slashes -> PagesController#destroy
  #
  # cadmus_pages accepts two additional options:
  #
  # * :controller - changes which controller it maps to.  By default, it is "pages" (meaning PagesController).
  # * :shallow - if set to "true", the edit, show, update and destroy routes won't include the "/pages" prefix.  Useful if you're
  #   already inside a unique prefix.
  def cadmus_pages(options = nil)
    options ||= {}
    options = options.with_indifferent_access

    controller = options[:controller] || 'pages'

    get "pages" => "#{controller}#index", :as => 'pages'
    get "pages/new" => "#{controller}#new", :as => 'new_page'
    post "pages" => "#{controller}#create"

    slug_constraint = Cadmus::SlugConstraint.new

    page_actions = Proc.new do
      get "*page_glob/edit" => "#{controller}#edit", :as => 'edit_page', :constraints => slug_constraint
      get "*page_glob" => "#{controller}#show", :as => 'page', :constraints => slug_constraint
      match "*page_glob" => "#{controller}#update", :constraints => slug_constraint, :via => [:put, :patch]
      delete "*page_glob" => "#{controller}#destroy", :constraints => slug_constraint
    end

    if options[:shallow]
      instance_eval(&page_actions)
    else
      scope 'pages' do
        instance_eval(&page_actions)
      end
    end
  end
end
