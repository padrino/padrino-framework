# Contributing to Padrino: notes for agents and humans

Padrino is a monorepo of gems built on Sinatra. This file collects the
project-specific things a contributor can't infer from the code: how to run
things, what CI checks, and the mistakes that have bitten past changes. It
applies to coding agents and people alike.

## Layout

- `padrino-core` (apps, routing, mounter, reloader, logger, CLI),
  `padrino-helpers` (view helpers, rendering), `padrino-gen` (generators and
  rake tasks), `padrino-admin`, `padrino-mailer`, `padrino-cache`,
  `padrino-support`, plus the `padrino` meta gem and `padrino-performance`.
- `CHANGES.rdoc` at the root is the changelog for all gems.
- The guides live in a separate repo,
  [padrino/padrino-docs](https://github.com/padrino/padrino-docs), and are
  published at <https://padrinorb.com>.

## Running things

```shell
bundle install
bundle exec rake test                     # every gem's suite
cd padrino-core && bundle exec rake test  # one gem
# one file, or one test by name:
cd padrino-gen && bundle exec ruby -Ilib -Itest -I../padrino/test test/test_project_generator.rb -n '/minitest/'
bundle exec rubocop <files you changed>
```

- Run suites one at a time. Some tests use fixed paths under `/tmp`, so two
  suites running at once can fail each other.
- `padrino-helpers/test/test_rendering.rb` errors when run on its own; run the
  padrino-helpers suite instead.
- Exercise generator changes through the real CLI as well as the tests, e.g.
  `ruby padrino-gen/bin/padrino-gen project demo -d sequel -e haml -t minitest --dev`,
  then `bundle install` and boot or test the generated project.

## What CI checks

- `bundle exec rake test` on Ruby 2.7 through 4.0 and JRuby, with HAML 5 and 7.
- The whole suite again with `RUBYOPT=--enable-frozen-string-literal`.

So, in code you add:

- **Ruby 2.7 syntax** (the gemspecs require `>= 2.7.8`): no endless methods,
  no `it` block parameter, no anonymous block, rest or keyword-rest arguments.
  RuboCop targets 2.7.
- **No mutation of string literals or of strings you were given** (`<<`,
  `gsub!`, `encode!`, `force_encoding` on a caller's string). Build a new
  string (`+''`, `dup`, `encode`) instead.
- **JRuby** runs the same suite; avoid MRI-only APIs.
- **Rack 3 and Sinatra 4** only.

## Every change

- **A regression test that fails without your fix.** Check it: revert the
  library change, watch the test fail for the right reason, then restore it.
  A test that passes either way proves nothing. Tests use minitest-spec
  (`describe`/`it`). Don't test counts or version strings, and don't match on
  source code.
- **Fix the whole class, not one instance.** Before you finish, grep for the
  same pattern elsewhere (other generators, other ORM components, other
  callers of the method) and fix or rule out each one.
- **A line in `CHANGES.rdoc`**, at the top of `== Unreleased`:
  `- FIX #<PR number> What changed, for users (@your-github-handle)`.
  The prefixes are `NEW`, `FIX`, `SEC`, `REMOVE` and `WARN` (for changes that
  can break existing apps).
- **RuboCop clean** on the files you touched; match the surrounding style.
- **Docs follow code.** A change to generator options, components or
  documented behaviour needs a matching PR on padrino-docs. There, regenerate
  `llms-full.txt` with `LANG=C.UTF-8 ruby scripts/generate_llms_txt.rb`.
  Docs for unreleased features are merged when the release ships.

## Pitfalls by area

### Generators (padrino-gen)

- Components are discovered from
  `padrino-gen/lib/padrino-gen/generators/components/<type>/<name>.rb`. A new
  file there is a new choice; there's no list to edit.
- Generators must be safe to run again on an existing project, since
  `padrino g component` applies to projects people have edited. Use
  `create_file ..., skip: true` for files users edit. Don't append a line that
  is already there. Start every appended line on a new line, so a file that
  lacks a trailing newline doesn't get its last line glued to yours.
- Generators also run without a terminal (CI, Dockerfiles, piped input). A
  prompt must stop with an error when input runs out, not ask again forever.
- Use `Padrino::Inflections` (`pluralize`, `underscore`, `camelize`,
  `constantize`) rather than `String#pluralize` and friends, which only exist
  when ActiveSupport is loaded.
- Test across the ORMs and template engines a change touches (e.g. sequel and
  activerecord; haml, slim and erb), with the real CLI.

### Routing, static files and access control

- Compare request paths the way the router sees them. Mustermann matches the
  percent-decoded path, so an authorization check on raw `request.path_info`
  can be bypassed by encoding one character. Decode first
  (`Rack::Utils.unescape_path`), and test an encoded variant.
- Prefix checks on paths need a separator: `"#{dir}/"`, not `dir`, so that
  `/posts` doesn't also match `/posts_admin`.
- Check behaviour for apps mounted at `/` and under a sub-path.

### Logger

- `Padrino.logger` can be any Ruby `Logger`, not only Padrino's. Guard calls
  to Padrino-only methods (`bench`, `devel`, ...) with `respond_to?`.
- Keep the default log output byte-identical unless changing it is the point.

### Rendering and mailers

- Template caches must be keyed by everything that selects the template,
  including the views path. Two mailers or apps can share a template name.
- Mail messages are rendered concurrently; keep per-message state on the
  message, not on the mailer class.

### Reloader

- Reloading is on only in development (`Padrino::Reloader.enabled`). A test
  that relies on it must enable it and restore the previous value in
  `ensure`.

## Security

Don't describe a vulnerability in a public issue or pull request. Report it
privately through GitHub's
[private vulnerability reporting](https://github.com/padrino/padrino-framework/security/advisories/new)
for this repository, and a maintainer will follow up.

## Pull requests

- Keep each PR to one change, with its test and CHANGES line.
- In the description, say how to reproduce the bug, show that the new test
  fails without the fix, list the suites and real-project checks you ran, and
  name anything you couldn't verify.
- If an agent wrote or helped write the change, report only results you
  actually saw: commands run and their output, not expectations.
