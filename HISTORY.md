## 0.7.0 (2013-xx-xx)
* Support for inherited instance variablesq
* Breaking change: Node#attribute block syntax no longer inherits
  context from current_object. See 941608e7 for more
* Breaking change: Drop ruby 1.8 support

## 0.6.1 (2013-02-18) -- yanked
* Feature: Add the ability to access instance variables set in sinatra
  actions in bldr templates.

## 0.6.0 (2012-xx-xx)
* Feature: Add the ability to pass-through objects directly to `object` and
  `collection` DSL methods

## 0.5.5 (2012-05-15)
* Bug: Allow .bldr extensions at the end of partial template names
* Bug: `#attribute` DSL method returns self, allowing use at top level

## 0.5.4 (2012-04-24)
* Fix bug to allow using `template` method at the root of a bldr template
* Add `locals` reader method to allow access to locals passed into a bldr template

## 0.5.3
* Add ability to use `attribute` method at the root-level in a bldr template
* Fix for when partials return nil (#19)

## 0.5.0 (2012-02-08)
* Add support "partials" (@ihunter)

## 0.2.0 (2011-09-09)
* Add new `attribute` inferred object syntax (@ihunter)

## 0.1.2 (2011-09-08)
* Return an empty collection when a nil value is passed to `collection` method
