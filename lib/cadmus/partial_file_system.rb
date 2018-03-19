module Cadmus
  # An implementation of Liquid's FileSystem interface that lets it read partials from a model that includes Cadmus::Partial
  class PartialFileSystem
    def initialize(parent)
      @parent = parent
    end

    def read_template_file(template_path)
      partial_scope.find_by!(partial_model.name_field => template_path).content
    end

    private

    def partial_model
      Cadmus.partial_model
    end

    def partial_scope
      if @parent
        partial_model.where(parent: @parent)
      else
        partial_model.global
      end
    end
  end
end

Liquid::Template.file_system = Cadmus::PartialFileSystem.new(nil)
