# Sensu Plugin

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugin.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugin)
[![Gem Version](https://badge.fury.io/rb/sensu-plugin.svg)](http://badge.fury.io/rb/sensu-plugin)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugin.svg)](https://gemnasium.com/sensu-plugins/sensu-plugin)

This is a framework for writing your own Sensu plugins and handlers.
It's not required to write a plugin (most Nagios plugins will work
without modification); it just makes it easier.

Examples of plugins written with and without it can be found in
the `sensu-plugins` organization.

## Checks and Metrics

To implement your own check, subclass `Sensu::Plugin::Check::CLI`, like
this:

```ruby
require 'sensu-plugin/check/cli'

class MyCheck < Sensu::Plugin::Check::CLI

  check_name 'my_awesome_check' # defaults to class name
  option :foo, :short => '-f' # Mixlib::CLI is included

  def run
    ok "All is well"
  end

end
```

This will output the string "my_awesome_check OK: All is well" (like a
Nagios plugin), and exit with a code of 0. The available exit methods,
which will immediately end the process, are:

 * `ok`
 * `warning`
 * `critical`
 * `unknown`

You can also call `message` first to set the message, then call an exit
method without any arguments (for example, if you want to choose between
WARNING and CRITICAL based on a threshold, but use the same message in
both cases).

For a metric, you can subclass either `Sensu::Plugin::Metric::CLI::JSON`
or `Sensu::Plugin::Metric::CLI::Graphite`. Instead of outputting a
Nagios-style line of text, these classes will output JSON-serialized
objects or Graphite messages.

```ruby
require 'sensu-plugin/metric/cli'

class MyJSONMetric < Sensu::Plugin::Metric::CLI::JSON

  def run
    ok "foo" => 1, "bar" => "anything"
  end

end
```

```ruby
require 'sensu-plugin/metric/cli'

class MyGraphiteMetric < Sensu::Plugin::Metric::CLI::Graphite

  def run
    ok "sensu.baz", 42
  end

end
```

JSON output takes one argument (the object), and adds a 'timestamp' key
if missing. Graphite output takes two arguments, the metric path and the
value, and optionally the timestamp as a third argument. `Time.now.to_i`
is used for the timestamp if it is not specified.

Exit codes do not affect metric output, but they can still be used by
your handlers.

Some metrics may want to output multiple values in a run. To do this,
use the `output` method, with the same arguments as the exit methods, as
many times as you want, then call an exit method without any arguments.

For either checks or metrics, you can override `output` if you want
something other than these formats.

### Options

For help on setting up options, see the `mixlib-cli` documentation.
Command line arguments that are not parsed as options are available via
the `argv` method.

### Utilities

Various utility methods will be collected under Sensu::Plugin::Util.
These won't depend on any extra gems or include actual CLI checks; it's
just for common things that many checks might want to do.

## Handlers

For your own handler, subclass `Sensu::Handler`. It looks much like
checks and metrics; see the `handlers` directory for examples. Your class
should implement `handle`. The instance variable `@event` will be set
for you if a JSON event can be read from stdin; otherwise, the handler
will abort. Output to stdout will go to the log.

You can decide if you want to handle the event by overriding the
`filter` method; but this also isn't documented yet (see the source; the
built in method does some important filtering, so you probably want to
call it with `super`).

### Important!

Filtering of events is now deprecated in `Sensu::Handler` and disabled
by default as of version 2.0.

Event filtering in this library may be enabled on a per-check basis by setting
the value of the check's `enable_deprecated_filtering` attribute to `true`.

These built-in filters will be removed in a future release. See
[this blog post](https://sensuapp.org/blog/2016/07/07/sensu-plugin-filter-deprecation.html)
for more detail.


## Mutator

For your own mutator, subclass `Sensu::Mutator`. It looks much like
checks and metrics; Your class should implement `mutate`. The instance variable
`@event` will be set for you if a JSON event can be read from stdin; otherwise,
the mutator will abort. Output to stdout will then be piped through to the
handler.  As described in the docs if a mutator fails to run the event will
not be handled.

The example mutator found [here](https://sensuapp.org/docs/latest/mutators) will
look like so:

```ruby
require 'sensu-mutator'

class MyMutator < Sensu::Mutator

  def mutate
    @event.merge!(:mutated => true)
  end

end
```

## Plugin settings

Whether you are writing a check, handler or mutator, Sensu's configuration
settings are available with the `settings` method (loaded automatically
when the plugin runs). We recommend you put your custom plugin settings
in a JSON file in `/etc/sensu/conf.d`, with a unique top-level key,
e.g. `my_custom_plugin`:

```
{
  "my_custom_plugin": {
    "foo": true,
    "bar": false
  }
}
```

And access them in your plugin like so:

```ruby
def foo_enabled?
  settings['my_custom_plugin']['foo']
end
```

## Contributing

 * Fork repository
 * Add functionality and any applicable tests
 * Ensure all tests pass by executing `bundle exec rake test`
 * Open a pull request

You may run individual tests by executing `bundle exec rake test TEST=test/external_handler_test.rb`

# License

Copyright 2011 Decklin Foster

Released under the same terms as Sensu (the MIT license); see LICENSE
for details.
