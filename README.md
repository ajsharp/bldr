[![Build Status](http://travis-ci.org/[ajsharp]/[bldr].png)](http://travis-ci.org/[ajsharp]/[bldr])


# Bldr

Bldr is a templating library that provides a simple DSL for generating
json documents from ruby objects. It currently supports Sinatra out of
the box -- Rails 3 support is planned for the near future.

If you would to contribute, pull requests with specs are warmly accepted :)

## Features

* Simple json templating DSL
* Uses Tilt's built-in rendering and template caching for better
  performance


## Installation

There are two ways to use Bldr in your Sinatra app, depending on whether
you are using Sinatra's classic or module application style:

```ruby

# Method 1: Classic style

require 'sinatra/bldr'

get '/hello' do
  bldr :hello
end


# Method 2: Modular style

require 'sinatra/bldr'

class MyApp < Sinatra::Base
  register Sinatra::Bldr
end
```


## Usage

```ruby
get "/endpoint" do
  # ...
  my_local_var = Object.new
  bldr :'path/to/template', {}, {:local_var => my_local_var}
end
```

## TODO

* Rails 3 support
* XML support

## Acknowledgements

* [RABL](http://github.com/nesquena/rabl) - Inspiration

## Copyright

Copyright (c) 2011 Alex Sharp. See the MIT-LICENSE file for full
copyright information.
