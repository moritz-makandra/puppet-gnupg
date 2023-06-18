# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0](https://github.com/h0tw1r3/puppet-gnupg/tree/2.0.0) (2023-06-17)

**Chores**

* Acceptance test framework changed from beaker to litmus
* Drop EOL operating systems from metadata
* Update to latest PDK template

## [1.5.1](https://github.com/h0tw1r3/puppet-gnupg/tree/1.5.1) (2023-05-22)

[Full Changelog](https://github.com/h0tw1r3/puppet-gnupg/compare/fork...1.5.1)

**Enhancements**

* Removed wget command requirement

**Chores**

* Test framework updated

## Unreleased

Forked version 1.2.3 of [golja/gnupg]. Cheers Dejan for the original module!

**Features**

* gnupg home support (Jan Vansteenkiste)

**Bugfixes**

* Work-around conflicts with other modules installing gnupg
* Replace deprecated URI.escape (Jon-Paul Lindquist)
* Fix module to work with directory environments (Matt Raso-Barnett)

**Chores**

* Replace params class with hiera data
* Add types to class parameters
* Reference documentation
* Converted to PDK

[golja/gnupg]: https://forge.puppet.com/modules/golja/gnupg
