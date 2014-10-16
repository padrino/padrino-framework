---
date: 2010-03-03
author: DAddYE
email: d.dagostino@lipsiasoft.com
title: Home Code
---

gem install padrino
    padrino g project myapp -d datamapper -b
    cd myapp
    padrino g admin
    padrino rake dm:migrate seed
    padrino start