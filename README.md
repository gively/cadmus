# Cadmus: an embeddable CMS for Rails

Cadmus is an embeddable content management system for Rails 3 applications.  It's based on [Liquid](http://liquidmarkup.org)
and is designed to be small and unobtrusive.

Cadmus doesn't define controllers or models itself, but rather, provides mixins to add CMS-like functionality to controllers
and models you create.  This allows a great deal of customization.  For example, Cadmus doesn't provide any user authentication
or authorization functionality, but because it hooks into controllers in your app, you can add virtually any authorization
system you want.

Similarly, Cadmus doesn't provide a Page model, but rather, a mixin for creating page-like models.  This theoretically allows
you to add functionality to your Page objects, include multiple different page-like models, or use any ActiveModel-compatible
ORM you want instead of ActiveRecord.

One additional feature is the ability for pages to have parents.  A parent can be any model object.  Page parent objects allow
you to create separate "sections" of your site - for example, if you have a project-hosting application that includes multiple
projects, each of which has its own separate space of CMS pages.  (Page parents aren't intended for creating sub-pages - 
instead, just use forward-slash characters in the page slug to simulate folders, and Cadmus will handle it.)

## Installation

First, add Cadmus to your Gemfile:

    gem 'cadmus'
    gem 'redcarpet'   # (required only if you intend to use Cadmus' Markdown support)

TODO: finish this section

## Copyright and Licensing

Copyright &copy; 2011-2012 Gively, Inc.  Cadmus is released under the MIT license.  For more information, see the LICENSE file.
