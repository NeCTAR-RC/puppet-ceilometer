class ceilometer::agent-notification inherits ceilometer {

  package {'ceilometer-agent-notification':
    ensure => installed,
  }

  service {'ceilometer-agent-notification':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-agent-notification'],
  }

  nagios::nrpe::service {'service_ceilometer_agent_notification':
    check_command => "/usr/lib/nagios/plugins/check_procs -c ${processorcount}:${processorcount} -u ceilometer -a /usr/bin/ceilometer-agent-notification";
  }

}
