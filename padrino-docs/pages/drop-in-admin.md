---
date: 2010-03-03
author: Nathan
email: nesquena@gmail.com
title: Drop-in Admin
---

Padrino is shipped with a slick and beautiful administration interface, with the following features:

||
|Orm Agnostic|Adapters for Active Record, MiniRecord, DataMapper, CouchRest, Mongoid, MongoMapper, Sequel, Ohm and Dynamoid|
|Authentication|User authentication and authorization management|
|Template Agnostic|Slim, Haml and ERB rendering support|
|Scaffold|You can create a new "admin interface" by providing a single Model|
|MultiLanguage|Translated into 10 languages including English, German and Russian|

Example:

    $ padrino-gen project cool -d datamapper
    $ cd cool
    $ padrino g admin

For more information, check out our detailed [Padrino Admin guide](/guides/padrino-admin).
