# @summary Manage gnupg and public key entries
#
# @param package_ensure
#   value passed to ensure param of package resource.
#   if package[gnupg] is already declared in the catalog, the package will not
#   be managed by this module.
#
# @param package_name
#   name of the package to ensure
#   supported operating systems have this value populated from hiera
#
# @example Basic installation
#   include gnupg
#
# @author Dejan Golja <dejan@golja.org>
#
class gnupg (
  String $package_ensure,
  String $package_name,
) {
  class { 'gnupg::install':
    ensure  => $package_ensure,
    package => $package_name,
  }
}
