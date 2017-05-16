require 'liquid'

require "cadmus/version"
require "cadmus/routing"
require "cadmus/renderers"
require "cadmus/slugs"
require "cadmus/tags"
require "cadmus/liquid_template_field"
require "cadmus/page"
require "cadmus/layout"
require "cadmus/pages_controller"
require "cadmus/layouts_controller"
require "rails"

module Cadmus
  class Engine < Rails::Engine
  end
end
