class ceilometer::alarm_notifier inherits ceilometer {
  package {'ceilometer-alarm-notifier':
    ensure => installed,
  }

  service {'ceilometer-alarm-notifier':
    ensure    => running,
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-alarm-notifier'],
  }

  nagios::nrpe::service {'service_ceilometer_alarm_notifier':
    check_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u ceilometer -a /usr/bin/ceilometer-alarm-notifier';
  }
}
