module Cadmus
  # An implementation of Liquid's FileSystem interface that lets it read partials from a model that includes Cadmus::Partial
  class PartialFileSystem
    def read_template_file(template_path)
      partial_model = Cadmus.partial_model
      partial_model.find_by!(partial_model.name_field => template_path).content
    end
  end
end

Liquid::Template.file_system = Cadmus::PartialFileSystem.new