# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### Changed
- The `deep_merge` implementation has changed to mirror that of Sensu Core (#123 via @amdprophet):
> Previously, if there were two conflicting data types in the same namespace (e.g. a Hash in one file, and an Array in another), sensu-plugin would throw an exception. It will now only use whatever loaded first, which is how Sensu Core handles this problem.

### Fixed
- Project tests updated to silence warnings by using `Minitest::Test` (#132 via @amdprophet).

## v1.3.0 (2016-06-06)

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

## v1.2.0 and earlier
- The changes in these releases are not presently documented
