class ceilometer::agent-compute inherits ceilometer::node {

  package {'ceilometer-agent-compute':
    ensure => installed,
  }

  service {'ceilometer-agent-compute':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-agent-compute'],
  }

  nagios::nrpe::service {'service_ceilometer_agent_compute':
    check_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ceilometer -a /usr/bin/ceilometer-agent-compute",
    use           => 'ignored-service',
  }

}
