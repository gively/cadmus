module Cadmus
  class Engine < Rails::Engine
    config.to_prepare do
      Cadmus.clear_partial_model_cache!
    end
  end
end