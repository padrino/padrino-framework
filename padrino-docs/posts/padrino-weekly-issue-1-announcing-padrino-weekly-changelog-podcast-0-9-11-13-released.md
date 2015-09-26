---
date: 2010-06-21
author: Florian
email: florian.gilcher@asquera.de
categories: Update
tags: padrino weekly
title: 'Padrino Weekly, Issue 1: Announcing Padrino Weekly, Changelog Podcast, 0.9.11
  - .13 Released'
---

Padrino Weekly will be a weekly summary of the activities in the Padrino ecosystem. The intention is to give all interested users a quick and easy way to follow the efforts of the core developers as well as the community as whole. We’ll try and provide pointers to important events, interesting discussions as well as contributions in the last or upcoming week. We’ll also point to long term developments that might be of interest.

<break>

Padrino was featured in last weeks [The Changelog](http://changelogshow.com/105/5806-episode-0-2-7-padrino-sinatra-based-ruby-web-framework), a podcast about new and exciting projects in Open Source. Arthur Chiu and Nathan Esquenazi had a 30 minute talk with Adam Stacoviak and Wynn Netherland. Topics were among other things a short rundown of the current core committers and how sinatra\_more became Padrino. Arthur and Nathan also elaborate on Sinatra and how it relates to Padrino, being the core of the framework.

This week saw three releases, 0.9.11 was released on friday making further steps towards stabilizing the API on the path to 1.0. The releases was quickly followed by 0.9.12 and 0.9.13 on saturday to fix two annoying bugs in the original release. 0.9.11 as the feature release features a refactored mailer, upgrades to the core router and improvements to the development reloading. It also adds a tiny project generation and support for choosing a specific database adapter on project creation. For a detailed list of changes see the [release announcement](http://www.padrinorb.com/blog/padrino-0-9-11-release-overview).

[Padrino recipes](http://github.com/padrino/padrino-recipes) are an ongoing long-term effort to simplify the usage of rack middleware in Padrino. It integrates a wealth of plugins ranging from payment over css to authentication via a number of authentication mechanisms. While not production ready yet we hope to roll the changes in one of the upcoming releases. We’ll keep you updated, in the meantime you’ll find further details [here](http://github.com/padrino/padrino-recipes).