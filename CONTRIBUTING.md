# Contributing to Padrino

Thanks for helping out! Bug reports, fixes and docs are all welcome. For a new
component or a larger feature, please open an issue first so we can agree on
the approach.

## Questions and bugs

- **Questions:** start with the [guides](https://padrinorb.com/guides/). If
  you're still stuck, open an
  [issue](https://github.com/padrino/padrino-framework/issues). Search the
  existing issues first.
- **Bugs:** open an issue with the steps to reproduce (a minimal app or a
  gist helps most), what you expected, and your Ruby, Padrino, Sinatra and
  Rack versions. The issue template asks for these.
- **Security problems:** don't open a public issue. Report them privately
  through
  [private vulnerability reporting](https://github.com/padrino/padrino-framework/security/advisories/new).

## Code changes

Fork the repository on GitHub, then:

```shell
git clone https://github.com/<you>/padrino-framework.git
cd padrino-framework
bundle install
bundle exec rake test
```

Then open a pull request with one change, its regression test and a line in
`CHANGES.rdoc`. [AGENTS.md](AGENTS.md) has the details: running single
tests, what CI checks, the changelog format, and the pitfalls past changes
ran into. It's written for coding agents and people alike.

## Docs and website

- The guides at padrinorb.com live in
  [padrino/padrino-docs](https://github.com/padrino/padrino-docs).
- The website itself lives in
  [padrino/padrino-web](https://github.com/padrino/padrino-web).

Fixes there are very welcome too; open a pull request in that repository.
