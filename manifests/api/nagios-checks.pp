# Nagios checks for ceilometer API
class ceilometer::api::nagios-checks {
  # These are checks that can be run by the nagios server.
  nagios::command {
    'check_ceilometer':
      check_command => '/usr/lib/nagios/plugins/check_http -p \'$ARG1$\' -e 401 -H \'$HOSTADDRESS$\' -I \'$HOSTADDRESS$\'';
    'check_ceilometer_ssl':
      check_command => '/usr/lib/nagios/plugins/check_http --ssl -p \'$ARG1$\' -e 401 -H \'$HOSTADDRESS$\' -I \'$HOSTADDRESS$\'';
  }
}

