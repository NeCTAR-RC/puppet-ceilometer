class ceilometer::collector inherits ceilometer {
  
  
  package {'ceilometer-collector':
    ensure => installed,
  }

  service {'ceilometer-collector':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-collector'],
  }
  
  nagios::nrpe::service {'service_ceilometer_collector':
    check_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ceilometer -a /usr/bin/ceilometer-collector";
  }

}
