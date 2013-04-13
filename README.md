[![Build Status](https://travis-ci.org/ajsharp/bldr.png)](https://travis-ci.org/ajsharp/bldr)


# Bldr

Bldr is a minimalist templating DSL that provides a simple syntax for generating
json documents from ruby objects. Bldr supports Sinatra and Rails
3.2 (3.0 and 3.1 may work, but have not been tested).

With bldr you can generate both simple and complex json documents:

```ruby
# app/views/posts/index.json.bldr

collection @posts do |post|
  attributes :title, :body, :created_at, :slug
  
  object :author => post.author do |author|
    attribute(:name) { author.display_name }
  end

  collection :comments => post.comments do |comment|
    attribute :spamminess
    attribute :created_at
    attribute(:body) do
      xss_filter(comment.body)
    end
  end
end
```

This would output the following json document:

```json
[
  {
    "title": "Some title",
    "body": "blah blah",
    "slug": "some-title",
    "created_at": "2013-04-11T15:46:17-07:00",
    "author": {
      "name": "Joe Author"
    },
    "comments": [
      {
        "spamminess": 1.0,
        "created_at": "2013-04-11T15:46:17-07:00",
        "body": "a comment"
      }
    ]
  }
]
```

## Why

If you're building an API, `Model#to_json` just doesn't cut it. Besides the JSON
representation of your models arguably being a presentation concern, trying
to cram all of this logic into an `#as_json` method quickly turns into pure chaos.

There are other json templating libraries available such as
[rabl](https://github.com/nesquena/rabl) or [json_builder](https://github.com/dewski/json_builder).
Bldr is in the same vein as these libraries, but with a simpler synxtax.

## Usage & Examples

See [Examples on the wiki](https://github.com/ajsharp/bldr/wiki/Documentation-&-Examples)
for documentation and usage examples.

## Installation

In your gemfile:

```ruby
gem 'bldr'
```

## Configuration

No additional configuration is required for rails applications.

For sinatra apps, dependening on whether you're using a modular or classic
application style, do one of the following:

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

### Vim

Add this line to your .vimrc:

```
au BufRead,BufNewFile *.bldr set filetype=ruby
```

### Emacs

Add this to your `~/.emacs.d/init.el`:

```
(add-to-list 'auto-mode-alist '("\\.bldr$" . ruby-mode))
```

## TODO

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
