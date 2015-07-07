class ceilometer::collector inherits ceilometer {

  $openstack_version = hiera('openstack_version')

  package {'ceilometer-collector':
    ensure => installed,
  }

  service {'ceilometer-collector':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-collector'],
  }

  $check_count = $ceilometer::collector_workers + 1

  nagios::nrpe::service {'service_ceilometer_collector':
    check_command => "/usr/lib/nagios/plugins/check_procs -c ${check_count}:${check_count} -u ceilometer -a /usr/bin/ceilometer-collector";
  }

}
