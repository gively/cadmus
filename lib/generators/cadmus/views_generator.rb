module Cadmus
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc "Copies Cadmus views to your application."
      source_root File.expand_path("../../../../app/views/cadmus", __FILE__)
      
      def copy_views
        directory :pages, "app/views/cadmus/pages"
      end
    end
  end
end