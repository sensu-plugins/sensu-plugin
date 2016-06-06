# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### Changed
- Refresh logic changed to subtract occurrences threshold before comparison; this changes alerting behavior in certain cases. (#82 from @ghicks-rmn)
- Update `Sensu::Handler` class to use `Timeout.timeout` in lieu of `Object#timeout` deprecated in ruby 2.3.0 (#117 from @ab)

### Added
- When set, value of SENSU_API_URL environment variable will supercede `api` settings when construcing API URL (#81 from @zbintliff)
- `api_request` method now supports https and http URLs as the value of `api.host`, backward compatible with non-url values (#102 from @zbintliff ).
- New `Sensu::Mutator` base class for writing mutator plugins (#106 from @zbintliff)

### Fixed
- `bail` method now properly returns error message in certain failure cases (#78 from @quodlibetor)

## v1.2.0 and earlier
- The changes in these releases are not presently documented
