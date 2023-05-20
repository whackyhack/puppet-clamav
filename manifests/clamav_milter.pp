# clamav_milter.pp
# Set up clamav_milter config and service.
#

class clamav::clamav_milter {

  unless ($::osfamily == 'RedHat') and (versioncmp($::operatingsystemrelease, '7.0') >= 0) {
    fail("OS family ${::osfamily}-${::operatingsystemrelease} is not supported. Only RedHat >= 7 is suppported.")
  }

  $config_options = $clamav::_clamav_milter_options

  if $clamav::clamav_milter_package {
    package { 'clamav_milter':
      ensure => $clamav::clamav_milter_version,
      name   => $clamav::clamav_milter_package,
      before => File['clamav-milter.conf'],
    }
  } else {
  # Default base in ClamAV's official package is /usr/local.
    if $clamav::clamav_base {
      $exec_path = "${clamav::clamav_base}/bin"
    } else {
      $exec_path = "/usr/local/bin"
    }
    systemd::unit_file { '/etc/systemd/system/clamav-milter.service':
      path    => $name,
      content => template('/etc/systemd/system/clamav-milter.service.erb'),
    }
  }


  file { 'clamav-milter.conf':
    ensure  => file,
    path    => $clamav::clamav_milter_config,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/clamav.conf.erb"),
  }

  service { 'clamav_milter':
    ensure     => $clamav::clamav_milter_service_ensure,
    name       => $clamav::clamav_milter_service,
    enable     => $clamav::clamav_milter_service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package['clamav_milter'], File['clamav-milter.conf']],
  }
}
