---
date: 2013-02-08
author: Florian
email: florian.gilcher@asquera.de
categories: Update
tags: security
title: Upgrade Rack immediately
---

All Rack users, including all Padrino users, should upgrade their [Rack](http://rack.github.com/) dependency as soon as possible. Multiple severe issues have been found, one of them including a potential remote code execution. This is espcially important if you are using Rack::Session::Cookie, which Padrino activates by default. See the Rack website for details.

To upgrade, use:

    bundle update rack

And make sure that you installed any of these versions: 1.5.2, 1.4.5, 1.3.10, 1.2.8, 1.1.6.