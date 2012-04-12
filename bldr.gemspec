# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bldr/version"

Gem::Specification.new do |s|
  s.name        = "bldr"
  s.version     = Bldr::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alex Sharp"]
  s.email       = ["ajsharp@gmail.com"]
  s.homepage    = "https://github.com/ajsharp/bldr"
  s.summary     = %q{Templating library with a simple, minimalist DSL.}
  s.description = %q{Provides a simple and intuitive templating DSL for serializing objects to JSON.}

  s.rubyforge_project = "bldr"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'multi_json'

  s.add_development_dependency 'json_pure'
  s.add_development_dependency 'sinatra',   '~>1.2.6'
  s.add_development_dependency 'tilt',      '~>1.3.2'
  s.add_development_dependency 'yajl-ruby', '>= 1.0'
  s.add_development_dependency 'actionpack', '~> 3.0.7'
end
