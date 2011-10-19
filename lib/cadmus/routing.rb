class SlugConstraint
	def self.matches?(request)
		page_glob = request.params["page_glob"] || request.path
		
		page_glob.sub(/^\//, '').split(/\//).all? do |part|
			part =~ /^[a-z][a-z0-9\-]*$/
		end
	end
end

ActionDispatch::Routing::Mapper.class_eval do
	def cadmus_pages(controller)
		get "pages" => "#{controller}#index"
		get "pages/new" => "#{controller}#new", :as => 'new_page'
		post "pages" => "#{controller}#create"

	  get "*page_glob/edit" => "#{controller}#edit", :as => 'edit_page', :constraints => SlugConstraint
  	get "*page_glob" => "#{controller}#show", :as => 'page', :constraints => SlugConstraint
	  put "*page_glob" => "#{controller}#update", :constraints => SlugConstraint
  	delete "*page_glob" => "#{controller}#destroy", :constraints => SlugConstraint

	end
end