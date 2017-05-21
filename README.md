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

## Basic Installation

First, add Cadmus to your Gemfile:

```ruby
gem 'cadmus'
gem 'redcarpet'   # (required only if you intend to use Cadmus' Markdown support)
```

The next step is to create a Page model.  Your app can have multiple Page models if you like, but for this example, we'll just
create one.

    rails generate model Page name:text slug:string content:text parent_id:integer parent_type:string

You'll need to tweak the generated migration and model slightly.  In the migration, after the `create_pages` block, add a
unique index on the parent and slug columns:

```ruby
add_index :pages, [:parent_type, :parent_id, :slug], :unique => true
```

And in the model, add a `cadmus_page` declaration:

```ruby
class Page < ActiveRecord::Base
  cadmus_page
end
```

You'll need a controller to deal with your pages.  Here's a minimal example of one:

```ruby
class PagesController < ApplicationController
  include Cadmus::PagesController

  protected
  def page_class
    Page
  end
end
```

If you're on Rails 4 (or using the `strong_parameters` gem) you'll probably want to use forbidden attributes protection.
Here's how you do that:

```ruby
class Page < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  cadmus_page
end
```

```ruby
class PagesController < ApplicationController
  include Cadmus::PagesController

  protected
  def page_params
    params.require(:page).permit(:name, :slug, :content)
  end

  def page_class
    Page
  end
end
```

`Cadmus::PagesController` automatically adds the seven RESTful resource methods to your controller.  It requires that you
define a `page_class` method that returns the class for pages it's dealing with.  (This could potentially return different
classes depending on request parameters, if you need it to - or, you could also set up different controllers for different
types of page.)

You'll also want to set up an initializer (probably in `config/initializers/cadmus.rb`) that will tell Cadmus how to generate URLs for pages.  This might look like this:

```ruby
Cadmus::Tags::PageUrl.define_page_path_method do |page_name, parent|
  page_path(page_name, parent_id: parent)
end
```

Doing this will enable markup like this in page templates: `<a href="{% page_url my-other-page %}">My other page</a>`.  The `{% page_url my-other-page %}` will be replaced with the actual URL for the page called `my-other-page`.

Finally, you'll need to create routes for this controller.  Cadmus provides a built-in helper for that:

```ruby
MyApp::Application.routes.draw do
  cadmus_pages
end
```

This will create the following routes:

* GET /pages => PagesController#index
* GET /pages/new => PagesController#new
* POST /pages => PagesController#create
* GET /pages/slug => PagesController#show
* PATCH /pages/slug => PagesController#update
* PUT /pages/slug => PagesController#update
* DELETE /pages/slug => PagesController#destroy

## Authorization Control

The pages controller is where you'll need to hook into any authorization or authentication system your app might use.
We use CanCan, so here's an example of how we do that:

```ruby
class PagesController < ApplicationController
  include Cadmus::PagesController

  authorize_resource :page

  protected
  def page_class
    Page
  end
end
```

```ruby
class Ability
  def initialize(user)
    can :read, Page
      return unless user

      # in this example, we've added an owner_id column to our Page model
      can :manage, Page, :owner_id => user.id
  end
end
```

Easy-peasy.  You can use other authorization plugins in a similar way - with Cadmus, you control the CMS models,
controllers and routes, so you can add whatever code is appropriate for your app.

## Pages With Parents

Suppose you've got an app that hosts web sites for local baseball teams.  Your app lets the teams manage their own
sites, and do stuff like add their team logo, uniform colors, roster, etc.  Now you'd like to let them add custom
content pages as well.

You already have the following routes set up in your routes.rb file:

```ruby
DugoutCoach::Application.routes.draw do
  resources :teams do
    resources :players
      resources :schedule
  end

  cadmus_pages # for global pages on your site
end
```

So, for example, the URL for the Cambridge Cosmonauts might be http://dugoutcoach.net/teams/cosmonauts.  They also
have http://dugoutcoach.net/teams/cosmonauts/players and http://dugoutcoach.net/teams/cosmonauts/schedule.

You can add a "pages" namespace pretty easily:

```ruby
DugoutCoach::Application.routes.draw do
  resources :teams do
    resources :players
      resources :schedule
      cadmus_pages :controller => :team_pages
  end

  cadmus_pages
end
```

Now you have a way of separating team-specific pages from global pages on the site.  The URLs for these pages might be,
for example, http://dugoutcoach.net/teams/cosmonauts/directions, or
http://dugoutcoach.net/teams/cosmonauts/promotions/free-hat-day (remember, Cadmus slugs can contain slashes).  We'll
now need a TeamPages controller to handle these:

```ruby
class TeamPagesController < ApplicationController
  include Cadmus::PagesController

  self.page_parent_class = Team   # page's parent is a Team
  self.page_parent_name = "team"  # parent ID is in params[:team_id]
  self.find_parent_by = "slug"    # parent ID is the Team's "slug" field rather than "id"

  authorize_resource :page

  protected
  def page_class
    Page
  end
end
```

Note that for this example, we've kept the same `Page` class for both controllers.  We could have also created a
separate `TeamPage` model, but that's not required.

### Shallow Page URLs

The Cambridge Cosmonauts are unhappy!  Their URLs are too long.  Why should the pages in their team site have a "/pages/"
in them just because they created them themselves?

Chill out, Cosmonauts.  Cadmus makes it easy:

```ruby
DugoutCoach::Application.routes.draw do
  resources :teams do
    resources :players
      resources :schedule
      cadmus_pages :controller => :team_pages, :shallow => true
  end

  cadmus_pages
end
```

Now the PagesController's `show`, `edit`, `update`, and `destroy` actions don't use the "/pages/" part of the URL.  The
URLs now look like this:

* GET /teams/cosmonauts/pages => PagesController#index
* GET /teams/cosmonauts/pages/new => PagesController#new
* POST /teams/cosmonauts/pages => PagesController#create
* GET /teams/cosmonauts/page-slug => PagesController#show
* GET /teams/cosmonauts/page-slug/edit => PagesController#edit
* PUT /teams/cosmonauts/page-slug => PagesController#update
* DELETE /teams/cosmonauts/page-slug => PagesController#destroy

When you use shallow page URLs, it's important to put the `cadmus_pages` declaration as the last one in the block,
because it's going to put a path-globbing wildcard in the scope from which it's called.  Thus, it should be the
lowest-priority route in its context.

## Liquid Variables

The Cambridge Cosmonauts have a policy of changing their uniform color on a weekly basis.  Why?  I don't know.  Go
Cosmonauts!

Needless to say, they don't want to go editing every single page where they mention that.  Fortunately, you can
help them by providing them with a Liquid template variable they can use like so:

```html
<h1>We're the Cosmonauts!</h1>

<p>Our uniform color this week is {{ team.uniform_color }}!</p>
```

To do this, you'll need to expose `team` as a Liquid assign variable:

```ruby
class TeamPagesController < ApplicationController
  include Cadmus::PagesController

  self.page_parent_class = Team   # page's parent is a Team
  self.page_parent_name = "team"  # parent ID is in params[:team_id]
  self.find_parent_by = "slug"    # parent ID is the Team's "slug" field rather than "id"

  authorize_resource :page

  protected

  def page_class
    Page
  end

  def liquid_assigns
    { :team => @page.parent }
  end
end
```

Defining a `liquid_assigns` method will cause Cadmus to use the return value of that method as the Liquid assigns hash.
(Similarly, you can define `liquid_filters` and `liquid_registers` methods that do what they say on the tin.)

You'll also need to make your Team model usable from Liquid.  The simplest way to do that is using `liquid_methods`:

```ruby
class Team < ActiveRecord::Base
  liquid_methods :name, :uniform_color

  # everything else in your model...
end
```

You could also define a `to_liquid` method that returns a `Liquid::Drop` subclass for Teams, if you need to do things
more complicated than just return data values.

## Liquid Templates on Non-Page Models

Let's say you have another model in your app that you'd like to put a Liquid template on.  For example, perhaps the baseball teams would like to send out a welcome email to their fans.  You might create a `WelcomeEmail` model with a `content` field.

Cadmus provides a convenience mixin to let you make that field a Liquid template.  You can use it like so:

```ruby
class WelcomeEmail < ActiveRecord::Base
  include Cadmus::Concerns::LiquidTemplateField

  liquid_template_field :content_liquid_template, :content

  belongs_to :team
end
```

Now if you call `my_welcome_email.content_liquid_template`, you'll get a parsed `Liquid::Template` generated from the value of `my_welcome_email.content`.  You could further make the WelcomeEmail into a `Cadmus::Renderable` to make it render the template:

```ruby
class WelcomeEmail < ActiveRecord::Base
  include Cadmus::Concerns::LiquidTemplateField
  include Cadmus::Renderable

  liquid_template_field :content_liquid_template, :content

  belongs_to :team

  def rendered_content
    cadmus_renderer.render(content_liquid_template, :html)
  end
end
```

Presto!  Now you can call `my_welcome_email.rendered_content`.  Since `WelcomeEmail` includes `Cadmus::Renderable`, you can also define `liquid_assigns` to expose variables to the template, for example:

```ruby
class WelcomeEmail < ActiveRecord::Base
  include Cadmus::Concerns::LiquidTemplateField
  include Cadmus::Renderable

  liquid_template_field :content_liquid_template, :content

  belongs_to :team

  def rendered_content
    cadmus_renderer.render(content_liquid_template, :html)
  end

  def liquid_assigns
    { 'team' => team }
  end
end
```

And now the welcome email templates can include `{{ team.name }}` and any other things derived from the Team model they want.

## Copyright and Licensing

Copyright &copy; Gively, Inc.  Cadmus is released under the MIT license.  For more information, see the LICENSE file.
