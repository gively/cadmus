module Cadmus
  class Engine < Rails::Engine
    config.to_prepare do
      Cadmus.clear_layout_model_cache!
      Cadmus.clear_page_model_cache!
      Cadmus.clear_partial_model_cache!
    end
  end
end