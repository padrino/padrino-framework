---
date: 2010-03-01
author: DAddYE
email: d.dagostino@lipsiasoft.com
title: Extensions
---

Extensions provide helper or class methods for Sinatra and Padrino applications. See [the Sinatra extensions page](http://www.sinatrarb.com/extensions-wild.html) for more information about this topic.

We also have some 3rd party extensions (ex: for ActiveRecord/MongoMapper/DataMapper, etc..) that are useful for web developers.

 

## Usage

If the extension is a gem put it in Gemfile otherwise create a file under your lib directory.

 

## Extension List

|What|Description|Where|
|:---|:----------|:----|
|Exception Notifier|Sends an email when an exception is raised|[gist](http://gist.github.com/308913#file_exception_notifier.rb)|
|Auto Locale|Sets for you I18n.locale parsing path\_info|[gist](http://gist.github.com/308919#file_auto_locale.rb)|
|Locale|Translates ActiveRecord attributes|[gist](http://gist.github.com/308915#file_locale.rb)|
|Permalink|Generates ActiveRecord permalinks for your fields|[gist](http://gist.github.com/308928#file_permalink.rb)|
|Flash|Helps setup cookie sessions with swfupload|[gist](http://gist.github.com/313322#file_flashmiddleware.rb)|