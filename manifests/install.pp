#
class gnupg::install {

  if !defined(Package['gnupg']) {
    ensure_resource('package', 'gnupg', {
      ensure => $gnupg::package_ensure,
      name   => $gnupg::package_name,
    })
  }

}