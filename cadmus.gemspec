# -*- encoding: utf-8 -*-
require File.expand_path('../lib/cadmus/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nat Budin", "Aziz Khoury"]
  gem.email         = ["natbudin@gmail.com", "bentael@gmail.com"]
  gem.description   = %q{Why deal with setting up a separate CMS?  Cadmus is just a little bit of CMS and fits nicely into your existing app.  It can be used for allowing users to customize areas of the site, for creating editable "about us" pages, and more.}
  gem.summary       = %q{Embeddable CMS for Rails 3 apps}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "cadmus"
  gem.require_paths = ["lib"]
  gem.version       = Cadmus::VERSION

  gem.add_dependency("rails", ">= 3.0.0")
  gem.add_dependency("liquid")
end
