---
date: 2010-03-08
author: DAddYE
email: d.dagostino@lipsiasoft.com
title: Agnostic
---

Padrino is **orm**, **javascript**, **testing**, **rendering**, **mocking** agnostic supporting the use of any number of available libraries.

The available components and their defaults are listed below:

|Component|Default|Options|
|:--------|:------|:------|
|orm|none|mongoid, ripple, activerecord, sequel, mongomapper, minirecord, ohm, mongomatic, dynamoid,
couchrest, datamapper|
|script|none|rightjs, extcore, dojo, prototype, jquery, mootools|
|renderer|none|slim, haml, erb|
|test|none|rspec, cucumber, minitest, steak, shoulda, riot, bacon|
|stylesheet|none|compass, sass, scss, less|
|mock|none|rr, mocha|

Just create the project with the usual generator command and pass in your preferred components!

    $ padrino g project cool --orm mongomapper
    $ padrino g project cool --renderer haml --stylesheet sass
    $ padrino g project cool --script mootools
    $ padrino g project cool --orm mongoid --script mootools
    $ padrino g project -h # shows available options
