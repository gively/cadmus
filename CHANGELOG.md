## cadmus 0.5.2 (11-10-2016)

* Rails 5 compatibility fixes

## cadmus 0.5.1 (05-03-2015)

* Support the sanitizer changes in Rails 4.2

## cadmus 0.5.0 (12-06-2013)

* First release that requires Rails 4.0
* Strong parameters compatibility by default

## cadmus 0.4.8 (07-16-2013)

* Add license info to gemspec

## cadmus 0.4.7 (07-15-2013)

* Bugfix: don't try to use the parameters in the new action.  This prevents us from raising errors unnecessarily for required params in Rails 4.

## cadmus 0.4.6 (07-15-2013)

* Changes for Rails 4 compatibility:
** Allow PUT or PATCH for the update action
** Implement a page_params protected method in page controllers, which you can override to get strong_parameters support

## cadmus 0.4.5 (03-04-2013)

* Change all the other uses of ^ and $ in regexes to \A and \z
* Change scope to use a lambda for Rails 4 compatibility

## cadmus 0.4.4 (03-04-2013)

* Change some uses of ^ and $ in regexes to \A and \z

## cadmus 0.4.3 (06-17-2012)

* Add a cadmus:views generator to make view customization easier

## cadmus 0.4.2 (06-16-2012)

* Make `cadmus_pages` route function work with no arguments
