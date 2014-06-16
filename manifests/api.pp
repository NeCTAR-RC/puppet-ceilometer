class ceilometer::api inherits ceilometer {

  $openstack_version = hiera('openstack_version')

  package {'ceilometer-api':
    ensure => installed,
  }

  service {'ceilometer-api':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-api'],
  }

  nagios::service {'ceilometer-api':
    check_command => 'http_port!8777',
    servicegroups => 'openstack-endpoints';
  }

  file {'/etc/ceilometer/policy.json':
    source => "puppet:///modules/ceilometer/${openstack_version}/policy.json",
  }

  nagios::nrpe::service {'service_ceilometer_api':
    check_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ceilometer -a /usr/bin/ceilometer-api";
  }

  firewall {'100 ceilometer':
    dport  => 8777,
    proto  => 'tcp',
    action => 'accept',
  }

}