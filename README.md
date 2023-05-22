# GnuPG module for Puppet

## Table of Contents

1. [Description](#description)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Overview

Manage PGP public and private keys in GnuPG keyrings.

## Setup

The command `gnupg` is required for the functions provided in this module.

Including the base class in a manifest will ensure the appropriate GnuPG
package is installed for a supported operating system.

```puppet
include gnupg
```

This is for convenience and may be skipped if you prefer to manage installing
the GnuPG command line tool.

## Usage

### Add public key from a remote server

```puppet
gnupg_key { 'hkp_server_20BC0A86':
  ensure     => present,
  key_id     => '20BC0A86',
  user       => 'root',
  key_server => 'hkp://pgp.mit.edu/',
  key_type   => 'public',
}
```

### Add public key from puppet

```puppet
gnupg_key { 'jenkins_foo_key':
  ensure     => present,
  key_id     => 'D50582E6',
  user       => 'foo',
  key_source => 'puppet:///modules/gnupg/D50582E6.key',
  key_type   => 'public',
}
```

### Remove public key

```puppet
gnupg_key { 'root_remove_20BC0A86':
  ensure   => absent,
  key_id   => '20BC0A86',
  user     => 'root',
  key_type => 'public',
}
```

### Remove both private and public keys

```puppet
gnupg_key { 'root_remove_20BC0A66':
  ensure   => absent,
  key_id   => '20BC0A66',
  user     => 'root',
  key_type => 'both',
}
```

## Limitations

Refer to the _Version Information_ section for this module on the
[Puppet Forge], or the `operatingsystem_support` key in [metadata.json]
of the source code.

## Development

Contributions are welcome and encouraged! Please submit a pull request to the
[project on Github]. Priority will be given to contributions that include
tests and documentation. If you're unfamiliar, that's okay, someone will help
guide you through the process.

## Acknowledgements

Forked from version 1.2.3 of the [gnupg] module developed by [Dejan Golja]

[Puppet Forge]: https://forge.puppet.com/modules/h0tw1r3/gnupg
[project on Github]: https://github.com/h0tw1r3/puppet-gnupg
[metadata.json]: metadata.json
[gnupg]: https://forge.puppet.com/modules/golja/gnupg
[Dejan Golja]: https://github.com/dgolja
