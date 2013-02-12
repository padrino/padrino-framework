---
author: Foo Bar
tags: padrino, release, version
categories: Update
title: Padrino 0.9.13 Gets Pushed Early
---

This latest release is a quick bug fix patch release for a few outstanding issues in 0.9.11. First, there was an issue
with the admin panel intermittently displaying in Czech rather than the English locale. This was due to a faulty key in
the localization file for Czech in admin.


The second bug had to do with routing failures in which certain routes wouldn't behave as expected if the same path was
defined twice with two different verbs (GET ‘/index’ and POST ‘/index’) as well as errors with the handling of provides
and explicit formats. An updated `http_router` and changes to routing in Padrino has addressed these issues in 0.9.13.


Finally, we have deprecated the mounting syntax related to ‘core’ applications. Prior to 0.9.13, the following code was
generated in a new project:


```ruby
Padrino.mount_core(“BlogDemo”)
```


This is actually somewhat confusing and hides what the mounter is actually doing. In the latest release, `mount_core` is
deprecated and the following is used instead:


```ruby
Padrino.mount(“BlogDemo”).to(“/”)
```


This is a minor change but important as this command is much more consistent and adheres to our philosophy of minimizing
‘magical’ behavior in our framework.


The quick version of these fixes is recapped below:


- Deprecated `mount_core` and remove references
- Fixed problem with Czech translation file
- Fixed a problem with routes with same path but different verbs and provides


Please update your applications to 0.9.13 and continue enjoy using Padrino!

