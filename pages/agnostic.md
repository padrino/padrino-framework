---
author: Foo Bar
title: Agnostic
label: Home Feature
---

Padrino is **orm**, **javascript**, **testing**, **rendering**, **mocking** agnostic supporting the use of any number of
available libraries.


The available components and their defaults are listed below:


| Component | Default | Options |
| orm       | none    | mongomapper, mongoid, activerecord, datamapper, sequel, couchrest |
| script    | none    | prototype, rightjs, jquery, mootools, extcore |
| renderer  | haml    | erb, haml |
| test      | rspec   | bacon, shoulda, cucumber, testspec, riot, rspec |
| stylesheet | none | less, sass |
| mock      | none | rr, mocha |


Just create the project with the usual generator command and pass in your preferred components!


    $ padrino g project cool -orm mongomapper
    $ padrino g project cool -renderer haml -stylesheet sass
    $ padrino g project cool -script mootools
    $ padrino g project cool -orm mongoid —script mootools
    $ padrino g project -h # shows available options

