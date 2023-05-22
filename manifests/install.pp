# @summary Install the package
# @api private
class gnupg::install (
  String $ensure,
  String $package,
) {
  if !defined(Package['gnupg']) {
    ensure_resource('package', 'gnupg', {
        ensure => $ensure,
        name   => $package,
    })
  }
}
