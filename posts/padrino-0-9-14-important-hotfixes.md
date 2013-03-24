---
date: 2010-07-01
author: Nathan
email: nesquena@gmail.com
categories: Ruby, Update
tags: padrino, release, version
title: Padrino 0.9.14 - Important Hotfixes
---

Padrino 0.9.14 is another small bugfix release which solves a few common problems revealed with the deprecation of `mount_core`. This is not at all a release which requires any changes to your app. The details of the bugs fixed are listed in the full post.

<break>

There are three major things fixed in this version. The biggest fix which has been causing a number of issues is the failure of Padrino to properly camelize application names. This causes a number of uninitialized constant failures for certain application names. This version re-factors the mounter so that this error no longer occurs and the correct application class is found in those failing cases. This should fix a number of associated issues related to failing migrations and scripts.

The next fix is we fixed a warning on mongo\_mapper because mongo\_mapper now requires bson\_ext instead of mongo\_ext. The generator has been changed to address this. We also fixed other minor issues that were affecting our users.

Here is a full list of changes in this version:

-   Application generator should create public subfolder
-   Refactored application mounter class
-   updated mongomapper to use bson\_ext
-   use entity code instead of copyright symbol
-   ensure app generation creates own public folder
-   fix padrino g alias
-   fixed distance\_of\_time\_in\_words helper(Thanks to Yannick Koechlin)

Please download this version as soon as you can to correct these important issue.