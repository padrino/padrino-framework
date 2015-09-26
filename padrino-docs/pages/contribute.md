---
date: 2010-03-29
author: Nathan
email: nesquena@gmail.com
title: Contribute
---

Want to show Padrino some love? Help out by contributing to our framework!

## Found a bug?

[Crate a new issue](http://github.com/padrino/padrino-framework/issues) at GitHub. Be sure to include all relevant information, like the versions of Padrino and Ruby you are using. A [Gist](http://gist.github.com/) of the code that caused the issue as well as any error messages are also most helpful.

## Want to integrate a component?

Have a particular JavaScript engine you like? Know of a popular ORM or testing framework that we have overlooked in Padrino generators? We encourage you to contribute by creating a patch to integrate your favorite components into Padrino! Check out the guide for [adding new components](http://www.padrinorb.com/guides/adding-new-components) to read a detailed walkthrough on how to do this!

## Want to help with documentation?

The process for contributing to Padrino’s website or documentation is as simple as forking the [padrino-framework](https://github.com/padrino/padrino-framework) repository and sending in any changes as a pull request. Once a change has been accepted, the documentation will be updated on our website. The website guides and docs are currently in the [GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown) format as can be seen for the [Getting Started](https://github.com/padrino/padrino-framework/blob/master/padrino-docs/guides/getting-started.md) guide.

There is also important YARD documentation within the framework code itself which could always use improvements. An example is the [asset tag](https://github.com/padrino/padrino-framework/blob/master/padrino-helpers/lib/padrino-helpers/asset_tag_helpers.rb) helpers file which is marked up with YARD annotations for every object and method.

Be sure to read over the [YARD Getting Started](http://rubydoc.info/docs/yard/file/docs/GettingStarted.md) and [Tag Overview](http://rubydoc.info/docs/yard/file/docs/Tags.md) guides for more details on this syntax. Every component of Padrino should be documented with YARD annotations which will be generated periodically to our [API](http://www.padrinorb.com/api/Padrino.html) documentation page.

You can also contact us for access to modifying the pages and guides within our site directly once you have had a patch accepted. Simply email <padrinorb@gmail.com> and request access.

## Code Guidelines

Padrino core contributors also have several code guidelines and conventions that we try and keep consistent within our codebase. We try to follow the common [Ruby code guidelines](http://pathfindersoftware.com/2008/10/elements-of-ruby-style) such as two space soft tab indentations, and we also like to keep a newline at the end of every ruby file.

Another convention to keep in mind is to minimize all trailing and unnecessary whitespace. If you are using TextMate, be sure to check out the [uberglory](https://github.com/glennr/uber-glory-tmbundle) which will automatically keep your code and spacing clean.

## Have a patch?

Bugs and feature requests that include patches are much more likely to get attention. Here are some guidelines that will help ensure your patch can be applied as quickly as possible:

1.  Use [Git](http://git-scm.com/) and [GitHub](http://github.com/): The easiest way to get started is to fork the [padrino-framework](http://github.com/padrino/padrino-framework) repository.
2.  Write unit tests: If you add or modify functionality, it must include unit tests. If you don’t write tests, we have to, and this can hold up acceptance of the patch.
3.  Mind the README: If the patch adds or modifies a major feature, modify the README.rdoc file to reflect that. Again, if you don’t update the README, we have to, and this holds up acceptance.
4.  Push it: Once you’re ready, push your changes to a topic branch and add a note to the ticket with the URL to your branch. Or, say something like, “you can find the patch on johndoe/foobranch”.

**NOTE:** we will take whatever we can get. If you prefer to attach diffs in emails to the mailing list, that’s fine; but do know that someone will need to take the diff through the process described above and this can hold things up considerably.

## Looking for something to do?

If you’d like to help out but aren’t sure how, take a look at the [GitHub Issues](http://github.com/padrino/padrino-framework/issues) page. If you find something that looks interesting, leave a comment on the ticket noting that you’re investigating (a simple “Taking…” is fine). Once you’ve worked on a few issues, someone will add you as an assignee.
