# init.pp
# Main class of clamav
# Declare main config here
#
# http://www.clamav.net
# http://www.clamxav.com
#
# @param $clamav_package
#  Package name of main application, usually 'clamav'.
#  You can now use ClamAV's official package, also named 'clamav'.
#
# @param $manage_clamav_milter
#  Whether to use this module to manage clamav-milter.
#  Do not set to true if you use ClamAV's official package because
#  as of 1.0.1 and 1.2.0, the package does not include clamav-milter binary.
#  And error is triggered if $manage_clamav_milter is true and $clamav_milter_package is undef.
#
# @param $clamd_package
#  Package name of SystemD support for clamd.
#  If you use ClamAV's official package, explicitly set this to undef.
#
# @param $freshclam_package
#  Package name of SystemD support for freshclam.
#  If you use ClamAV's official package, explicitly set this to undef.
#
# @param $clamav_milter_package
#  Package name of SystemD support for clamav-milter.
#  If you use ClamAV's official package, explicitly set this to undef.
#
# @param $clamav_base
#  Path to clamav install base.
#  Unused except for ClamAV's official package, which may differ
#  from conventions used by Linux distributions.
#

class clamav (
  Boolean $manage_user          = $clamav::params::manage_user,
  Boolean $manage_repo          = $clamav::params::manage_repo,
  Boolean $manage_clamd         = $clamav::params::manage_clamd,
  Boolean $manage_freshclam     = $clamav::params::manage_freshclam,
  Boolean $manage_clamav_milter = $clamav::params::manage_clamav_milter,
  String $clamav_package        = $clamav::params::clamav_package,
  String $clamav_version        = $clamav::params::clamav_version,
  String $clamav_base           = $clamav::params::clamav_base,

  $user                         = $clamav::params::user,
  Optional[String] $comment     = $clamav::params::comment,
  $uid                          = $clamav::params::uid,
  $gid                          = $clamav::params::gid,
  Stdlib::Absolutepath $home    = $clamav::params::home,
  Stdlib::Absolutepath $shell   = $clamav::params::shell,
  $group                        = $clamav::params::group,
  $groups                       = $clamav::params::groups,

  String $clamd_package         = $clamav::params::clamd_package,
  String $clamd_version         = $clamav::params::clamd_version,
  Stdlib::Absolutepath $clamd_config = $clamav::params::clamd_config,
  String $clamd_service         = $clamav::params::clamd_service,
  $clamd_service_ensure         = $clamav::params::clamd_service_ensure,
  Boolean $clamd_service_enable = $clamav::params::clamd_service_enable,
  Hash $clamd_options           = $clamav::params::clamd_options,

  $freshclam_package            = $clamav::params::freshclam_package,
  $freshclam_version            = $clamav::params::freshclam_version,
  Stdlib::Absolutepath $freshclam_config = $clamav::params::freshclam_config,
  $freshclam_service            = $clamav::params::freshclam_service,
  $freshclam_service_ensure     = $clamav::params::freshclam_service_ensure,
  Boolean $freshclam_service_enable = $clamav::params::freshclam_service_enable,
  Hash $freshclam_options       = $clamav::params::freshclam_options,
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig = $clamav::params::freshclam_sysconfig,
  Optional[String] $freshclam_delay = $clamav::params::freshclam_delay,

  $clamav_milter_package        = $clamav::params::clamav_milter_package,
  $clamav_milter_version        = $clamav::params::clamav_milter_version,
  $clamav_milter_config         = $clamav::params::clamav_milter_config,
  $clamav_milter_service        = $clamav::params::clamav_milter_service,
  $clamav_milter_service_ensure = $clamav::params::clamav_milter_service_ensure,
  $clamav_milter_service_enable = $clamav::params::clamav_milter_service_enable,
  $clamav_milter_options        = $clamav::params::clamav_milter_options,
) inherits clamav::params {

  # Avoid inconsistent signaling of official ClamAV package
  if ($manage_freshclam AND $manage_clamd AND ($freshclam_package XOR $clamd_package)) {
    fail('If $manage_freshclam and $manage_clamd are both set, either use both $freshclam_package and $clamd_package or set them both to undef.')
  }

  # clamd
  $_clamd_options = merge($clamav::params::clamd_default_options, $clamd_options)

  # freshclam
  $_freshclam_options = merge($clamav::params::freshclam_default_options, $freshclam_options)

  # clamav_milter
  if $manage_clamav_milter {
    unless $clamav_milter_package {
    # As of 1.0.1 and 1.2.0, ClamAV's official package does not include clamav-milter binary.
      fail('$clamav_milter_package is needed.')
    }
    assert_type(String, $clamav_milter_package)
    assert_type(String, $clamav_milter_version)
    assert_type(Stdlib::Absolutepath, $clamav_milter_config)
    assert_type(String, $clamav_milter_service)
    assert_type(Boolean, $clamav_milter_service_enable)
    assert_type(Hash, $clamav_milter_options)
    $_clamav_milter_options = merge($clamav::params::clamav_milter_default_options, $clamav_milter_options)
  }

  if $manage_repo { require 'epel' }

  if $manage_user {
    Anchor['clamav::begin']
    -> class { 'clamav::user': }
    -> Class['clamav::install']
  }

  if $manage_clamd {
    Class['clamav::install']
    -> class { 'clamav::clamd': }
    -> Anchor['clamav::end']
  }

  if $manage_freshclam {
    Class['clamav::install']
    -> class { 'clamav::freshclam': }
    -> Anchor['clamav::end']
  }

  if $manage_clamav_milter {
    Class['clamav::install']
    -> class { 'clamav::clamav_milter': }
    -> Anchor['clamav::end']
  }

  anchor { 'clamav::begin': }
  -> class { 'clamav::install': }
  -> anchor { 'clamav::end': }
}
