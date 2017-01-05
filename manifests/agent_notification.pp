class ceilometer::agent_notification inherits ceilometer {

  package {'ceilometer-agent-notification':
    ensure => installed,
  }

  service {'ceilometer-agent-notification':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-agent-notification'],
  }

  if $::ceilometer::openstack_version == 'juno' {
    $procs = 2
  } else {
    $procs = 1
  }

  nagios::nrpe::service {'service_ceilometer_agent_notification':
    check_command => "/usr/lib/nagios/plugins/check_procs -c ${procs}:${procs} -u ceilometer -a bin/ceilometer-agent-notification";
  }

}
