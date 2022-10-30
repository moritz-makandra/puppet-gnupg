# @summary Set module defaults
# @api private
class gnupg::params {
  $package_ensure = 'present'

  case $facts['os']['family'] {
    'Debian': {
      $package_name ='gnupg'
    }
    'RedHat': {
      $package_name = 'gnupg2'
    }
    'Suse': {
      $package_name = 'gpg2'
    }
    default: {
      fail("${facts['os']['family']} is not supported")
    }
  }
}
