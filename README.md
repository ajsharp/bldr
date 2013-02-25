[![Build Status](https://travis-ci.org/ajsharp/bldr.png)](https://travis-ci.org/ajsharp/bldr)


# Bldr

Bldr is a minimalist templating library that provides a simple DSL for generating
json documents from ruby objects. It currently supports Sinatra out of
the box -- Rails 3 support is planned for the near future.

If you would like to contribute, pull requests with specs are warmly accepted :)

## Why

If you're building an API, `Model#to_json` just doesn't cut it. Besides the JSON
representation of your models arguably being a presentation concern, trying
to cram all of this logic into an `#as_json` method quickly turns into pure chaos.

There are other json templating libraries available -- [rabl](http://github.com/nesquena/rabl) being the most popular -- but I wasn't satisfied with any of the DSL's, so I created Bldr.

## Features

* Simple json templating DSL
* Uses Tilt's built-in rendering and template caching for better performance
* Partials

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

See the [Documentation & Examples](https://github.com/ajsharp/bldr/wiki/Documentation-&-Examples) page on the wiki.

## Deprecations & Breaking Changes

### 0.7.0: current_object deprecation

The use of `current_object` is now deprecated. Instead of referencing `current_object` in bldr templates
use block variables in `object` and `collection` methods:

```ruby
# OLD (deprecated)
collection :people => people do
  attribute(:name) { current_object.name }
end

# NEW
collection :people => people do |person|
  attribute(:name) { person.name }
end
```

Make use of block variables the same way for the `object` method:

```ruby
# OLD (deprecated)
object :person => person do
  attributes :name, :age

  person = current_object
  object :address => person.address do
    # current_object here would be assigned to person.address
    attribute(:zip) { current_object.zip_code }
    attribute(:address_title) { person.display_name }
  end
end

# NEW
object :person => person do |person|
  attributes :name, :age

  object :adress => person.address do |address|
    attribute(:zip) { address.zip_code }
    attribute(:address_title) { person.display_name }
  end
end
```

### 0.7.0: attribute method breaking change

One of the forms of the `attribute` method has changed in the 0.7.0 release.
Previously, using the dynamic block form of `attribute`, if you did not pass
in a block variable, the block would be eval'd in context of the `current_object`.
This behavior fails the "principle of least surprise" test.

0.7.0 changes this behavior by simply executing the block in context of `Bldr::Node`, which provides
access to instance variables and locals available in that context.

```ruby
# OLD
object :person => person do
  attribute(:name) { display_name } # equivalent to doing attribute(:name) { |person| person.display_name }
end

# NEW
object :person => @person do
  attribute(:name) { @person.display_name }
end
```

See [941608e](https://github.com/ajsharp/bldr/commit/d0bfbd8) and [d0bfbd8](https://github.com/ajsharp/bldr/commit/d0bfbd8) for more info.

## Editor Syntax Support

To get proper syntax highlighting in vim, add this line to your .vimrc:

```
au BufRead,BufNewFile *.bldr set filetype=ruby
```

## TODO

* Rails 3 support.  An attempt for this was made for this but was reverted in e1cfd7fcbe130b316d95773d8c73ece4e247200e.  Feel free to take a shot.
* XML support

## Acknowledgements

* [RABL](http://github.com/nesquena/rabl) - Inspiration
* [Tilt](https://github.com/rtomayko/tilt) - Mega awesome templating goodness

## Contributors

* Ian Hunter (@ihunter)
* Justin Smestad (@jsmestad)
* Adam LaFave (@lafave)

## Copyright

Copyright (c) 2011-2013 Alex Sharp. See the MIT-LICENSE file for full
copyright information.
