
Gem::Specification.new do |s|
  s.name    = "bldr"
  s.version = '0.1.0'
  s.authors = ["Alex Sharp"]
  s.email   = ["ajsharp@gmail.com"]
  s.homepage = "https://github.com/ajsharp/bldr"
  s.summary = "Minimalist templating library."

  s.add_dependency 'multi_json', '~> 1.0.3'

  s.add_development_dependency 'json_pure'
  s.add_development_dependency 'sinatra',   '~>1.2.6'
  s.add_development_dependency 'tilt',      '~>1.3.2'
  s.add_development_dependency 'yajl-ruby'

end
