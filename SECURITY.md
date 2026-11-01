# Security policy

## Supported versions

| Version | Supported |
| ------- | --------- |
| 0.18.x  | Yes |
| 0.17.x  | Security fixes only |
| < 0.17  | No |

The latest minor release gets every fix. The minor before it gets security
fixes until the next minor ships. Upgrade to the latest patch release of a
supported minor to get them.

## Reporting a vulnerability

Please don't report a vulnerability in a public issue, pull request or chat
channel. Report it privately through GitHub's
[private vulnerability reporting](https://github.com/padrino/padrino-framework/security/advisories/new)
for this repository. Include the affected gem and version, what an attacker can
do, and the steps or code to reproduce it.

A maintainer will acknowledge the report, confirm whether it's a vulnerability,
and work with you on a fix and an advisory. We credit reporters in the advisory
and in `CHANGES.rdoc` unless you'd rather not be named.

This policy covers the gems in this repository: `padrino`, `padrino-core`,
`padrino-helpers`, `padrino-gen`, `padrino-admin`, `padrino-mailer`,
`padrino-cache`, `padrino-support` and `padrino-performance`, including the code
that `padrino-gen` and `padrino-admin` generate.
