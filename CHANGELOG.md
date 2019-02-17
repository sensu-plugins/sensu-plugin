# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### [4.0.0] - 2018-02-17
### Breaking Changes
- remove support for EOL ruby `< 2.3` as they are EOL (@majormoses)

### Changed
- appease the cops (@majormoses)

## [3.0.1] - 2018-01-07
### Fixed
- locked `mixlib-cli` dep to `~> 1.5` as `2.0` removes ruby support for `< 2.5` (@majormoses)

## [3.0.0] - 2018-12-04
### Breaking Changes
- renamed event mapping utility function `map_v2_event_into_v1` to match naming change to Sensu Go `map_go_event_into_ruby` (@jspaleta)
- renamed mutator and handler mixin arguments from `--map-v2-event-into-v1` to match naming change to Sensu Go `--map-go-event-into-ruby` (@jspaleta)
- renamed envar option from `SENSU_MAP_V2_EVENT_INTO_V1` to `SENSU_MAP_GO_EVENT_INTO_RUBY` (@jspaleta)
- updated `map_go_event_into_ruby` logic to account for entity attribute refactor (@jspaleta)
-
### Added
- `map_go_event_info_ruby` now takes optional `map_annotation` argument to indicate annotation key
  holding json string to be mapped into ruby entity attributes
  default value is "sensu.io.json_attributes"
  optional envvar SENSU_MAP_ANNOTATION to use as environment override (@jspaleta)
- add mutator-go-into-ruby.rb  binary. This mutator command can be used to mutate Sensu Go events into Sensu Core 1.x events (@jspaleta)

## [2.7.0] - 2018-09-12
### Added
- Added map_v2_event_into_v1 method to Utils for all plugin classes to use. (@jspaleta)
- Added --map-v2-event-into-v1 runtime commandline option to base Handler and Mutator classes. (@jspaleta)
- Alternatively set envvar SENSU_MAP_V2_EVENT_INTO_V1=1 and handlers/mutators will automatically attempt to map 2.x event data. (@jspaleta)
- New cli option/envvar makes it possible to use sensu-plugin based handlers/mutators
  with Sensu 2.0 events until they provide native 2.0 event support internally. (@jspaleta)
- Mapping function sets and checks for boolean event attribute 'v2_event_mapped_into_v1',
  to prevent mapping from running multiple times in same pipeline. (@jspaleta)

## [2.6.0] - 2018-08-28
### Fixed
- Fix `paginated_get` for backward compatibility with Sensu API < 1.4 (@cwjohnston).

## [2.6.0] - 2018-08-28
### Added
- Added utils method `paginated_get` for iteratively retrieving API responses (@cwjohnston).

## [2.5.0] - 2018-04-03
### Added
- Added Handler Sensu API HTTPS support through API configuration (e.g. `{"api": {"ssl": {}}` (@portertech).

## [2.4.0] - 2018-02-08
### Added
- Added subclass for Generic metrics output to support multiple metrics output formats (@bergerx)

### Changed
- updated metrics class inheritance hierarchy (@bergerx)

## [2.3.0] - 2017-08-17
### Added
- Added subclass for InfluxDB output (@luisdavim)
- Added subclass for DogStatsD output (@luisdavim)

### Changed
- updated changelog to be more inline with current standard for plugins (@majormoses)

## [2.2.0] - 2017-08-15
### Added
- Added rubocop test to the Rakefile (@luisdavim)

## [v2.1.0] - 2017-07-06
### Added
- Added cast_bool_values_int helper method to convert boolean values to integers

## [v2.0.1] - 2017-04-28
### Changed
- Update json module requirement to < 3.0.0

## [v2.0.0] - 2017-03-29
### Breaking Change
IMPORTANT! This release includes the following potentially breaking changes:

- Plugins now exit with status `3` (unknown) when encountering an
  exception or being run with bad arguments.
- Removed support for Ruby 1.9 and earlier.
- Deprecated filtering methods in this library are now disabled by default. For more information read this [blog post](https://blog.sensuapp.org/deprecating-event-filtering-in-sensu-plugin-b60c7c500be3)

## [v1.4.5] - 2017-03-07
### Added
- Added support for globally disabling deprecated filtering methods via the
  `sensu_plugin` configuration scope. See README for example.

### Fixed
## [v1.4.4] - 2016-12-08

- Fixed a regression in Sensu::Handler `api_request` method, introduced in
  v1.4.3, which broke silence stashes and check dependencies on Ruby 2.x.

## [v1.4.3] - 2016-10-04
### Fixed
- Fixed an incompatibility with Ruby 1.9 introduced in Sensu::Handler api_request circa sensu-plugin 1.3.0
- Fixed Sensu::Handler check dependency filtering by using plural form `events` API endpoint, instead of singular-form `event`.
- Fixed a condition where `config_files` method may attempt to read from a non-existent file.

## [v1.4.2] - 2016-08-08
### Fixed
- Fixed a condition in which empty strings in check `dependencies` attribute values would cause an exception. (#147 via @rs-mrichmond)

## [v1.4.1] - 2016-08-03
### Fixed
- Actually fix dependency loading problems in Ruby 1.9 environments by changing 'json' dependency from `<= 2.0.0` to `< 2.0.0`. (#149 via @cwjohnston)

## [v1.4.0] - 2016-07-20

### Breaking Change
- Filtering of events is now deprecated in `Sensu::Handler` and will be removed in a future release. See [this blog post](https://sensuapp.org/blog/2016/07/07/sensu-plugin-filter-deprecation.html) for more detail.

### Changed
- Warnings are now visible in handler output when deprecated event filtering is used, as it is by default. (#139 via @cwjohnston)
- Filtering of events can now be disabled on a per-check basis by setting value of custom attribute `enable_deprecated_filtering` to `false` (#139 via @cwjohnston)
- Filtering of events based on occurrences can now be disabled on a per-check basis by setting value of custom attribute `enable_deprecated_occurrence_filtering` to `false`  (#139 via @cwjohnston)
- The `deep_merge` implementation has changed to mirror that of Sensu Core (#123 via @amdprophet):

 > Previously, if there were two conflicting data types in the same namespace (e.g. a Hash in one file, and an Array in another), sensu-plugin would throw an exception. It will now only use whatever loaded first, which is how Sensu Core handles this problem.

- The api_request method now defaults `api` configuration host 127.0.0.1 and port 4567 when configuration has not been provided via `SENSU_API_URL` environment variable nor Sensu JSON configuration.
- Dependency on 'json' changed to '<= 2.0.0' to avoid dependency loading problems in Ruby 1.9 environments. (#138 via @nibalizer)

### Fixed
- Now explicitly requiring 'json' in sensu-plugin/utils to avoid empty settings confusion (#141 via @zroger)
- Project tests updated to silence warnings by using `Minitest::Test` (#132 via @amdprophet).
- Now exiting with return code `3` (UNKNOWN) when plugin `require` statements raise an exception. Previously this would cause plugins to exit with status `0`. (#121 via @fessyfoo)

## [v1.3.0] - 2016-06-06

### Changed
- Refresh logic changed to subtract occurrences threshold before comparison; this changes alerting behavior in certain cases. (#82 from @ghicks-rmn)
- Update `Sensu::Handler` class to use `Timeout.timeout` in lieu of `Object#timeout` deprecated in ruby 2.3.0 (#117 from @ab)
- Update dependency on mixlib-cli from '>= 1.1.0' to '>= 1.5.0' (aa59019 from @mattyjones, see #93)
- Timeout for API requests in `stash_exists?` method increased from 2 seconds to 5 seconds. (3e9ac7e from @analytically, see #99)

### Added
- When set, value of SENSU_API_URL environment variable will supersede `api` settings when constructing API URL (#81 from @AlexisMontagne)
- `api_request` method now supports https and http URLs as the value of `api.host`, backward compatible with non-url values (#102 from @zbintliff ).
- New `Sensu::Mutator` base class for writing mutator plugins (#106 from @zbintliff)
- Checks now only run at_exit when @@autorun is not false.  This allows for easier rspec testing of checks and is how handlers currently work.(#116 from @zbintliff)

### Fixed
- `bail` method now properly returns error message in certain failure cases (#78 from @quodlibetor)
- `Sensu::Plugin::CLI::Graphite` no longer appends unnecessary line endings to output which cause graphite to drop metrics (#114 from @petecheslock)

## Earlier versions

The changes in earlier releases are not fully documented but comparison links are available:

* [v1.2.0]
* [v1.1.0]
* [v1.0.0]
* [v0.3.0]
* [v0.1.7]
* [v0.1.6]
* [v0.1.5]
* [v0.1.4]
* [v0.1.3]
* [v0.1.2]
* [v0.1.1]
* [v0.1.0]

[Unreleased]: https://github.com/sensu-plugins/sensu-plugin/compare/4.0.0...HEAD
[4.0.0]: https://github.com/sensu-plugins/sensu-plugin/compare/3.0.1...4.0.0
[3.0.1]: https://github.com/sensu-plugins/sensu-plugin/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/sensu-plugins/sensu-plugin/compare/2.7.0...3.0.0
[2.7.0]: https://github.com/sensu-plugins/sensu-plugin/compare/2.6.1...2.7.0
[2.6.1]: https://github.com/sensu-plugins/sensu-plugin/compare/2.6.0...2.6.1
[2.6.0]: https://github.com/sensu-plugins/sensu-plugin/compare/2.5.0...2.6.0
[2.5.0]: https://github.com/sensu-plugins/sensu-plugin/compare/2.4.0...2.5.0
[2.4.0]: https://github.com/sensu-plugins/sensu-plugin/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/sensu-plugins/sensu-plugin/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v2.1.0...2.2.0
[v2.1.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v2.0.1...v2.1.0
[v2.0.1]: https://github.com/sensu-plugins/sensu-plugin/compare/v2.0.0...v2.0.1
[v2.0.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.4.5...v2.0.0
[v1.4.5]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.4.4...v1.4.5
[v1.4.4]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.4.3...v1.4.4
[v1.4.3]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.4.2...v1.4.3
[v1.4.2]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.4.1...v1.4.2
[v1.4.1]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.4.0...v1.4.1
[v1.4.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.3.0...v1.0.0
[v0.3.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.7...v0.3.0
[v0.1.7]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.6...v0.1.7
[v0.1.6]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.5...v0.1.6
[v0.1.5]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.4...v0.1.5
[v0.1.4]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.3...v0.1.4
[v0.1.3]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.2...v0.1.3
[v0.1.2]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.1...v0.1.2
[v0.1.1]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.1.0...v0.1.1
[v0.1.0]: https://github.com/sensu-plugins/sensu-plugin/compare/v0.0.6...v0.1.0
