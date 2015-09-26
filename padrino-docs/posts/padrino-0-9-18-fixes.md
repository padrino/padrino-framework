---
date: 2010-10-22
author: Arthur
email: mr.arthur.chiu@gmail.com
categories: Press, Ruby, Update
tags: fixes padrino mime sequel postgres
title: Padrino 0.9.18 fixes!
---

Padrino 0.9.18 provides some additional fixes from both the team and the community as well as an update to the latest http\_router. thanks guys!

<break>

-   Updated to use latest http\_router
-   Fix undefined method crypted\_password when using Postgresql + Sequel [Thanks to Commuter]
-   Preserve params for after use by a before filter
-   Fix const scope for Rack::Mime [Thanks to spllr]