# Padrino Performance

Performance tools for Padrino.


## Installation

Add `padrino-performance` to your `Gemfile` of your Padrino application.

Install the gem with

    $ bundle install


## Available suites

- JSON: Tell you if you have conflicting libraries being declared in your `Gemfile`. Why? Because they would nearly do the same job and this will help you to detect it.
    - You can it by passing the `-j` or `--json` option.
- Memory: Print the memory usage of your application when it is started.
    - You can it by passing the `-j` or `--json` option.


## Usage

`bundle exec padrino-performance SUITE -- bundle exec padrino COMMAND`

E.g.:

- Measure json on a console:

    bundle exec padrino-performance -j -- bundle exec padrino console
    >> require 'json'
    >> require 'json_pure'

    Then you will get some error reports in the terminal, which indicates that you have
    conflicting json libraries that do the same


- Measure memory on a running app:

    bundle exec padrino-performance -m -- bundle exec padrino start
    # The output will be the following

     total    44056K
     total    44980K
    => Padrino/0.11.2 has taken the stage development at http://127.0.0.1:3000
    >> Thin web server (v1.5.1 codename Straight Razor)
    >> Maximum connections set to 1024
    >> Listening on 127.0.0.1:3000, CTRL+C to stop

