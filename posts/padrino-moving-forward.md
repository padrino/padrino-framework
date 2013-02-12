---
author: Foo Bar
tags: padrino, info
categories:
title: Padrino Moving Forward
---

The reason we originally built Padrino is that Sinatra by nature was intentionally constrained to be very limited in
scope. This was by design and the constraint is what allows Sinatra to be universally accessible and useful for a wide
variety of projects.


Sinatra will never grow much outward in scope because the developers behind it rightfully feel that any additional scope
added to Sinatra itself would be a disservice. Instead, Sinatra is a perfect foundation to be built onto by other
projects that can add additional functionality and grow the size and scope of what is possible during development.


This is where Padrino fits into the ecosystem. As one of the original creators of ‘sinatra_more’ and ‘padrino’, I
personally never intend for Padrino to abandon the Sinatra roots. It is important to me that Padrino simply build on the
foundation provided by Sinatra. Part of this means keeping the scope of Padrino constrained as well. When we first
started this project, we knew there were a set number of things that needed to be added to Sinatra in an organic and
natural way. This set has always been roughly the same since the project creation:


1) Admin Panel Functionality (ala Django)
2) User Authentication and Permissions
3) View Helpers and Form Builders for templates
4) Generators for providing better default structure
5) Advanced routing, controller and alias functionality
6) Easy to use integrated mailer
7) Localization support baked-in
8) Caching (fragment, page, action) and adapters for cache storage


Beyond this there are some other niceties such as code reloading in development, better logging, et al. Really Padrino
in it’s entirety does do quite a bit to extend Sinatra’s scope in almost every direction towards more powerful
application development.


However, I feel we are not looking to expand the constrained scope this project has. In other words, those goals above
are really the extent of what we want to bring to the table and all other major functionality can be tacked on as
Padrino extensions rather than into core.


Obviously there is still **a lot** of work to do and Padrino will continue to grow. There are a few features left to
finish (improved helpers, [nested forms](https://github.com/padrino/padrino-framework/issues#issue/188) ,
[ujs support](https://github.com/padrino/padrino-framework/issues#issue/158)) which are mostly half finished. Also as
always we need better tutorials, better documentation, support for more components, bug fixes, better test coverage, et
al.  This is the direction going forward.


Padrino is **not** looking be rails or YAWB (yet another web framework).  Sinatra is already a tested and proven
development option and we plan to continue our quest to make Sinatra development so flexible that it can be used for the
smallest one line app or an advanced e-commerce consumer site without sacrificing what makes the development experience
so pleasant.


As always, we are also open to hearing any feedback Padrino users might have. So please let us know in irc (#padrino) or
in the [Padrino google groups](http://groups.google.com/group/padrino) or through
[github](https://github.com/padrino/padrino-framework) (pull requests, tickets or otherwise). Also, if you want to help
out Padrino in anyways please do let us know (or simply send me a message through github).

