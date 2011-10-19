module Cadmus
	class SlugConstraint
		def matches?(request)
			page_glob = request.symbolized_path_parameters[:page_glob]
			
			# assert_recognizes doesn't pass the full params hash as we would in a real Rails
			# application.  So we have to always pass this constraint if we're testing.
			return true if page_glob.nil? && Rails.env.test?
			
			page_glob.sub(/^\//, '').split(/\//).all? do |part|
				part =~ /^[a-z][a-z0-9\-]*$/
			end
		end
	end
end

ActionDispatch::Routing::Mapper.class_eval do
	def cadmus_pages(options)	
		options = options.with_indifferent_access
		
		controller = options[:controller] || 'pages'
		
		get "pages" => "#{controller}#index", :as => 'pages'
		get "pages/new" => "#{controller}#new", :as => 'new_page'
		post "pages" => "#{controller}#create"

		slug_constraint = Cadmus::SlugConstraint.new
		
		page_actions = Proc.new do
			get "*page_glob/edit" => "#{controller}#edit", :as => 'edit_page', :constraints => slug_constraint
			get "*page_glob" => "#{controller}#show", :as => 'page', :constraints => slug_constraint
			put "*page_glob" => "#{controller}#update", :constraints => slug_constraint
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