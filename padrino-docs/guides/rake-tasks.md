---
date: 2010-03-01
author: Nathan
email: nesquena@gmail.com
title: Rake Tasks
---

After generating a new padrino project, you will not find any Rakefile in your generated project folder structure; in fact it’s not strictly needed to build a new one because we can already use padrino rake:

    padrino rake
    # or for a list of tasks
    padrino rake -T

If you need custom tasks you can add those to:

-   *your\_project*/**lib/tasks**
-   *your\_project*/**tasks**
-   *your\_project*/**test**
-   *your\_project*/**spec**

Padrino will look recursively for any `*.rake` file in any of these directories.

Padrino by default has some useful tasks.

 

## Basic

Like other frameworks we have an *:environment* task that loads our `environment` and apps. Example:

    # This is a custom task
    # task/version.rake
    task :version => :environment do
      puts Padrino.version
    end

 

## Routes

*currently not in stable release (coming in 0.9.10)*

We have support for retrieving a list of named routes within your application for easy access.

    padrino rake routes

which will return all the named routes for your project:

    Application: core
                     URL  REQUEST  PATH
      (:guides, :search)    GET    /guides/search
       (:guides, :index)    GET    /guides
        (:guides, :show)    GET    /guides/:id

    Application: foo
         (:blog, :index)    GET    /blog
          (:blog, :show)    GET    /blog/:id

 

## Testing

When testing with Padrino you have a builtin `padrino rake test` or for rspec `padrino rake spec`.

    padrino rake test # => for bacon, riot, shoulda
    padrino rake spec # => for rspec

you can customize *test/test.rake* or *spec/spec.rake*

 

## I18n

You can auto generate a *yml* file for localizing your models using this command:

    padrino rake locale:models

See [Localization](/guides/localization) for detailed instructions.

 

## Orm

Padrino has rake tasks for *DataMapper* , *ActiveRecord*, *Sequel*, *Mongomapper*,and *Mongoid* with some **bonuses**.

**NOTE**: we have a **namespace** for each orm, because of this, Padrino can mount several applications and each of them can use different orms without conflict, so that you can have multiple applications living together and one of them can use DataMapper, while another *ActiveRecord/MongoMapper/Couch/Sequel* instead. In this way we prevent collisions.

#### ActiveRecord Tasks:

    rake ar:abort_if_pending_migrations    # Raises an error if there are pending migrations.
    rake ar:auto:upgrade                   # Uses schema.rb to auto-upgrade.
    rake ar:charset                        # Retrieves database charset.
    rake ar:collation                      # Retrieves databsae collation.
    rake ar:create                         # Creates the database as defined in config/database.yml
    rake ar:create:all                     # Creates local databases as defined in config/database.yml
    rake ar:drop                           # Drops the database for the current Padrino.env
    rake ar:drop:all                       # Drops local databases defined in config/database.yml
    rake ar:forward                        # Pushes the schema to the next version.
    rake ar:migrate                        # Migrates the database through scripts in db/migrate.
    rake ar:migrate:down                   # Runs the "down" for a given migration VERSION.
    rake ar:migrate:redo                   # Rollbacks current migration and migrates up to version
    rake ar:migrate:reset                  # Resets your database using your migrations.
    rake ar:migrate:up                     # Runs the "up" for a given migration VERSION NUMBER
    rake ar:reset                          # Drops and recreates the database using db/schema.rb.
    rake ar:rollback                       # Rolls back the schema to previous schema version.
    rake ar:schema:dump                    # Creates a portable db/schema.rb file.
    rake ar:schema:load                    # Loads a schema.rb file into the database.
    rake ar:schema:to_migration            # Creates a migration from schema.rb
    rake ar:schema:to_migration_with_reset # Creates a migration and resets the migrations log.
    rake ar:setup                          # Creates the database, loads the schema, and seeds data.
    rake ar:structure:dump                 # Dumps the database structure to a SQL file.
    rake ar:version                        # Retrieves the current schema version number.

**rake ar:auto:upgrade**

This is some sort of super cool and useful task for people like me who don’t love migrations (especially for small apps). It’s a forked version of [auto\_migrations](http://github.com/pjhyett/auto_migrations)

Basically, instead of writing migrations you can directly edit your **schema.rb** and perform *a non destructive* migration with `padrino rake ar:auto:upgrade`.

#### DataMapper Tasks:

    rake dm:auto:migrate           # Performs an automigration (resets your db data)
    rake dm:auto:upgrade           # Performs a non destructive automigration
    rake dm:create                 # Creates the database
    rake dm:drop                   # Drops the database (postgres and mysql only)
    rake dm:migrate                # Migrates the database to the latest version
    rake dm:migrate:down[version]  # Migrates down using migrations
    rake dm:migrate:up[version]    # Migrates up using migrations
    rake dm:reset                  # Drops the database, and migrates from scratch
    rake dm:setup                  # Create the database migrate and initialize with the seed data

#### Sequel Tasks:

    rake sq:migrate:auto           # Perform automigration (reset your db data)
    rake sq:migrate:to[version]    # Perform migration up/down to VERSION
    rake sq:migrate:up             # Perform migration up to latest migration available
    rake sq:migrate:down           # Perform migration down (erase all data)

#### Mongomapper Tasks:

    rake mm:translate              # Generates .yml files for I18n translations

#### Mongoid Tasks:

Available in 0.9.21

    rake mi:drop                    # Drops all the collections for the database for the current environment
    rake mi:create_indexes          # Create the indexes defined on your mongoid models
    rake mi:objectid_convert        # Convert string objectids in mongo database to ObjectID type
    rake mi:cleanup_old_collections # Clean up old collections backed up by objectid_convert

#### Seed:

Like in Rails we can populate our db using *db/seeds.rb* here’s an example (from our padrino-admin):

    email     = shell.ask "Which email do you want use for loggin into admin?"
    password  = shell.ask "Tell me the password to use:"
     
    shell.say ""
     
    account = Account.create(:email => email, :password => password, 
                             :password_confirmation => password, :role => "admin")
     
    if account.valid?
      shell.say "Perfect! Your account was created."
      shell.say ""
      shell.say "Now you can start your server with padrino start and then login into /admin with:"
      shell.say "   email: #{email}"
      shell.say "   password: #{password}"
      shell.say ""
      shell.say "That's all!"
    else
      shell.say "Sorry but some thing went worng!"
      shell.say ""
      account.errors.full_messages.each { |m| shell.say "   - #{m}" }
    end