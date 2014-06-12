class ceilometer::alarm-evaluator inherits ceilometer {

  package {'ceilometer-alarm-evaluator':
    ensure => installed,
  }

  service {'ceilometer-alarm-evaluator':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-alarm-evaluator'],
  }

  nagios::nrpe::service {'service_ceilometer_agent_central':
    check_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ceilometer -a /usr/bin/ceilometer-alarm-evaluator";
  }

}
