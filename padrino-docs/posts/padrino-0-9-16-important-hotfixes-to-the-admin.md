---
date: 2010-09-24
author: DAddYE
email: d.dagostino@lipsiasoft.com
categories: Update
tags: padrino, ruby, admin
title: Padrino 0.9.16 - Important Hotfixes to the Admin
---

We pushed a new version of Padrino with some new good features and important fixed to our admin.

<break>

Here the list of changes:

-   Fixed problems with admin
-   Now only AS \> 3.0
-   Added padrino-cache
-   Added redis backend for padrino-cache
-   Added dom helpers [Thanks to nu7hatch]
-   Added regex support for route portions
-   Update rspec generation to use let() [Thanks to rbxbx]
-   Added mysql2 support for activerecord [Thanks to kyanagi]
-   Fixed riot test helper generation
-   Added concise routing support
-   Added controller mapping support
-   Fixed tests to support concurrency
-   Fixed options\_for\_selec to be Array-compatible [Thanks to zmack]
-   Support Sinatra before blocks correctly
-   Added support for shallowing in controllers
-   Remove padrino-admin dependency on padrino-gen [Thanks to selman]