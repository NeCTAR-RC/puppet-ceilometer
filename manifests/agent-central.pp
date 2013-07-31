class ceilometer::agent-central inherits ceilometer {
  
  
  package {'ceilometer-agent-central':
    ensure => installed,
  }

  service {'ceilometer-agent-central':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-agent-central'],
  }

  nagios::nrpe::service {'service_ceilometer_agent_central':
    check_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ceilometer -a /usr/bin/ceilometer-agent-central";
  }

}
