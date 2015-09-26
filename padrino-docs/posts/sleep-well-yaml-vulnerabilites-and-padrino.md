---
date: 2013-02-03
author: Florian
email: florian.gilcher@asquera.de
categories: Update
tags: ''
title: 'Sleep well: YAML vulnerabilites and Padrino'
---

Rails and the Ruby community had their fair share of security vulnerabilities in the recent days. Where does that leave Padrino users?

In short: You are safe, unless you explicitely activated some form of parameter parsing that either parses YAML directly or uses XmlMini when accepting requests or parsing responses from backend sources.

<break>

Currently, some security issues plagued the Rails community. The most dangerous is [CVE-156](https://groups.google.com/forum/#!topic/rubyonrails-security/61bkgvnSGTQ/discussion) , which is present in almost all Rails installations. Default Sinatra and Padrino are unaffected, see [this discussion](https://groups.google.com/forum/#!msg/sinatrarb/nUzRwTzkycU/ILoXoHxwn-0J) on the Sinatra mailing list for details. All hints given there are true for Padrino users as well.

If you are using any of the Rails components in question either directly or through dependencies, you should upgrade them. The most important components in question are YAML (both Psych and Syck) or XmlMini. Popular projects using them are [Rack::Parser](https://github.com/achiu/rack-parser) (fixed) and [Rack::PostBodyToParams](https://github.com/niko/rack-post-body-to-params). If you use the first: run `bundle upgrade` and make sure you get version `0.2.0` and higher! Update: The same goes for rack-post-body-params (see the comments).

## What are those attacks about and how can I validate my stack?

The [safe\_yaml README](https://github.com/dtao/safe_yaml) explains it very well. Basically, `YAML.load` allows you to instantiate arbitary objects, which is the first step to running arbitrary code. Any code path leading to a `YAML.load` of untrusted (read: external) data is a potential vulnerability. This includes consuming data accepted from web services or parsing Gemspecs.

To validate that you are safe, take the following steps:

-   Make a list of all libraries that you are using to accept data – Request parsers and webservice clients are the most popular ones. Padrino does not silently activate any of them, all have been added by yourself.
     – Check if any of those use YAML.load somewhere (a simple `grep` should suffice)
     + Check what is loaded: local configuration data is fine, external data is not
     + If you want to be on the safe side, see if you application runs well with [safe\_yaml](https://rubygems.org/gems/safe_yaml)
-   Check if you or any of those libraries have any dependency to XmlMini
     – If yes, upgrade XmlMini to at least 0.5.2

## Make your application ready for Padrino 0.11

While nothing of “upgrade now!”-severity, the soon to be released Padrino 0.11 contains a few important security additions, especially XSS-safe rendering using `ActiveSupport::SafeBuffer`. Test you application against the current master so that you can upgrade when it is released.

## A final word

Finally, I’d like to say thank you to all Rails contributors working on fixing the found bugs and the Rubygems team for fixing Rubygems.org as fast as they did. Also a big thank you to everyone that found those vulnerabilities.