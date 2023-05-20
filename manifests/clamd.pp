# clamd.pp
# Set up clamd config and service.
#

class clamav::clamd {

  $config_options = $clamav::_clamd_options

  if $clamav::clamd_package {
    package { 'clamd':
      ensure => $clamav::clamd_version,
      name   => $clamav::clamd_package,
      before => File['clamd.conf'],
    }
  } else {
  # Default base in ClamAV's official package is /usr/local.
    if $clamav::clamav_base {
      $exec_path = "${clamav::clamav_base}/sbin"
    } else {
      $exec_path = '/usr/local/sbin'
    }
    systemd::unit_file { '/etc/systemd/system/clamad@.service':
      path => $name,
      content => template('/etc/systemd/system/clamd@.service.erb'),
    }
  }


  file { 'clamd.conf':
    ensure  => file,
    path    => $clamav::clamd_config,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/clamav.conf.erb"),
  }

  service { 'clamd':
    ensure     => $clamav::clamd_service_ensure,
    name       => $clamav::clamd_service,
    enable     => $clamav::clamd_service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package['clamd'], File['clamd.conf']],
  }
}
