# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [v1.4.2] - 2016-08-08

- Fixed a condition in which empty strings in check `dependencies` attribute values would cause an exception. (#147 via @rs-mrichmond)

## [v1.4.1] - 2016-08-03

### Changed
- Actually fix dependency loading problems in Ruby 1.9 environments by changing 'json' dependency from `<= 2.0.0` to `< 2.0.0`. (#149 via @cwjohnston)

## [v1.4.0] - 2016-07-20

### Important
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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugin/compare/v1.4.2...HEAD
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
