---
author: Foo Bar
title: Rake Tasks
---

After generating a new Padrino project, you will not find any Rakefile in your generated project folder structure; in
fact it's not strictly needed to build a new one because we can already use `padrino rake`:

    $ padrino rake # or for a list of tasks padrino rake -T


If you need custom tasks you can add those to:

- `your_project_/*lib/tasks` `your_project_/*tasks`
- `your_project_/*test` `your_project_/*spec`


Padrino will look recursively for any `*.rake` file in any of these directories.


Padrino by default has some useful tasks.


## Basic

Like other frameworks we have an *:environment* task that loads our `environment` and apps. Example:


```ruby
# This is a custom task
# task/version.rake
task :version => :environment do
  puts padrino.version
end
```


## Routes

We have support for retrieving a list of named routes within your application for easy access.


    $ padrino rake routes


which will return all the named routes for your project:


    Application: core
    URL REQUEST PATH
     GET /guides/search
     GET /guides
     GET /guides/:id

    Application: foo
     GET /blog
     GET /blog/:id


## Testing

When testing with Padrino you have a builtin `padrino rake test` or for rspec `padrino rake spec`.


    $ padrino rake test # => for bacon, riot, shoulda
    $ padrino rake spec # => for rspec


you can customize `test/test.rake` or `spec/spec.rake`


## I18n

You can auto generate a *yml* file for localizing your models using this command:


    $ padrino rake locale:models


See [TBD]() for detailed instructions.


## Orm

Padrino has rake tasks for *DataMapper* , *ActiveRecord*, *Sequel*, *Mongomapper*,and *Mongoid* with some **bonuses**.


**NOTE**: we have a **namespace** for each orm, because of this, Padrino can mount several applications and each of them
can use different orms without conflict, so that you can have multiple applications living together and one of them can
use `DataMapper`, while another *ActiveRecord/MongoMapper/Couch/Sequel* instead. In this way we prevent collisions.


### ActiveRecord Tasks:

    rake ar:abort_if_pending_migrations # Raises an error if there are pending migrations
    rake ar:charset # Retrieves the charset for the current environment's database
    rake ar:collation # Retrieves the collation for the current environment's database
    rake ar:create # Create the database defined in config/database.yml for the current Padrino.env
    rake ar:create:all # Create all the local databases defined in config/database.yml
    rake ar:drop # Drops the database for the current Padrino.env
    rake ar:drop:all # Drops all the local databases defined in config/database.yml
    rake ar:forward # Pushes the schema to the next version.
    rake ar:migrate # Migrate the database through scripts in db/migrate
    and update db/schema.rb by invoking ar:schema:dump. Target specific
    version with VERSION=x. Turn off output with VERBOSE=false.
    rake ar:migrate:down # Runs the "down" for a given migration VERSION.
    rake ar:migrate:redo # Rollbacks the database one migration and re
    migrate up.
    rake ar:migrate:reset # Resets your database using your migrations for
    the current environment
    rake ar:migrate:up # Runs the "up" for a given migration VERSION.
    rake ar:reset # Drops and recreates the database from db/schema.rb for
    the current environment and loads the seeds.
    rake ar:rollback # Rolls the schema back to the previous version.
    rake ar:schema:dump # Create a db/schema.rb file that can be portably
    used against any DB supported by AR
    rake ar:schema:load # Load a schema.rb file into the database
    rake ar:setup # Create the database, load the schema, and initialize
    with the seed data
    rake ar:structure:dump # Dump the database structure to a SQL file
    rake ar:translate # Generates .yml files for I18n translations
    rake ar:version # Retrieves the current schema version number


**rake ar:auto:upgrade**

This is some sort of super cool and useful task for people like me who don't love migrations. It's a forked version of
[auto_migrations](http://github.com/pjhyett/auto_migrations)


Basically, instead of writing migrations you can directly edit your `schema.rb` and perform *a non destructive*
migration with `padrino rake ar:auto:upgrade`.


### DataMapper Tasks:

    rake dm:auto:migrate # Performs an automigration
    rake dm:auto:upgrade # Performs a non destructive automigration
    rake dm:create # Creates the database
    rake dm:drop # Drops the database
    rake dm:migrate # Migrates the database to the latest version
    rake dm:migrate:down[version] # Migrates down using migrations
    rake dm:migrate:up[version] # Migrates up using migrations
    rake dm:reset # Drops the database, and migrates from scratch
    rake dm:setup # Create the database migrate and initialize with the seed data


### Sequel Tasks:

    rake sq:migrate:auto # Perform automigration
    rake sq:to[version] # Perform migration up/down to VERSION
    rake sq:up # Perform migration up to latest migration available
    rake sq:down # Perform migration down


### Mongomapper Tasks:

    rake mm:drop # Drops all the collections for the database for the current Padrino.env
    rake mm:translate # Generates .yml files for I18n translations


### Mongoid Tasks:

Available in 0.9.21

    rake mi:drop # Drops all the collections for the database for the current environment
    rake mi:create_indexes # Create the indexes defined on your mongoid models
    rake mi:objectid_convert # Convert string objectids in mongo database to ObjectID type
    rake mi:cleanup_old_collections # Clean up old collections backed up by objectid_convert


### Seed:

Like in Rails we can populate our db using `db/seeds.rb` here's an example :


```ruby
email = shell.ask "Which email do you want use for loggin into admin?"
password = shell.ask "Tell me the password to use:"

shell.say ""

account = Account.create

if account.valid?
  shell.say "Perfect! Your account was created."
  shell.say ""
  shell.say "Now you can start your server with padrino start and then
  login into /admin with:"
  shell.say " email: #"
  shell.say " password: #"
  shell.say ""
  shell.say "That's all![]("
  else
  shell.say "Sorry but some thing went worng)"
  shell.say ""
  account.errors.full_messages.each { |m| shell.say "- #{m}" }
end
```

