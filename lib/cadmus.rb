require 'liquid'

require "cadmus/version"

require "cadmus/concerns/controller_with_parent"
require "cadmus/concerns/model_with_parent"
require "cadmus/concerns/liquid_template_field"
require "cadmus/concerns/other_class_accessor"

require "cadmus/routing"
require "cadmus/renderers"
require "cadmus/slugs"
require "cadmus/tags"
require "cadmus/page"
require "cadmus/layout"
require "cadmus/partial"
require "cadmus/partial_file_system"
require "cadmus/pages_controller"
require "cadmus/partials_controller"
require "cadmus/layouts_controller"

require "rails"
require "cadmus/engine"

module Cadmus
  extend Cadmus::Concerns::OtherClassAccessor
  other_class_accessor :partial_model
end