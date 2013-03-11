# Padrino Performance

Performance tools for Padrino.

## "Installation"

Add ```padrino-performance``` to your ```Gemfile```.

## Available suites 

* JSON. ```-j``` or ```--json``` option.
* Memory.

## Basic usage

```bundle exec padrino-performance SUITE -- bundle exec padrino COMMAND```

E.g.:

* Measure json on a console:
```bundle exec padrino-performance -j -- bundle exec padrino console```

* Measure memory on a running app: 
```bundle exec padrino-performance -m -- bundle exec padrino start```
