class ceilometer::api($workers=1) inherits ceilometer {

  include uwsgi

  $worker_name = 'uwsgi-worker-ceilometer-api'
  $wsgi_file = '/etc/ceilometer/app.wsgi'
  $openstack_version = hiera('openstack_version')

  package {'ceilometer-api':
    ensure => installed,
  }

  service {'ceilometer-api':
    ensure    => 'stopped',
    subscribe => File['ceilometer-config'],
    require   => Package['ceilometer-api'],
  }

  nagios::service {'ceilometer-api':
    check_command => 'check_ceilometer!8777',
    servicegroups => 'openstack-endpoints';
  }

  file {'/etc/ceilometer/policy.json':
    source => "puppet:///modules/ceilometer/${openstack_version}/policy.json",
  }

  file {$wsgi_file:
    source => "puppet:///modules/ceilometer/${openstack_version}/app.wsgi",
    owner => 'ceilometer',
    group => 'ceilometer',
  }

  nagios::nrpe::service {'service_ceilometer_api':
    check_command => "/usr/lib/nagios/plugins/check_procs -c ${workers}:${workers} -u ceilometer -a ${worker_name}";
  }

  uwsgi::manage_app {'ceilometer-api':
    ensure => 'present',
    uid => 'ceilometer',
    gid => 'ceilometer',
    config => {
      http-socket => ':8777',
      master => 'true',
      plugin => 'python',
      enable-threads => 'true',
      need-app => 'true',
      buffer-size => '16384',
      timeout => '300',
      pecan => $wsgi_file,
      processes => $workers,
      procname => $worker_name,
      procname-master => 'uwsgi-master-ceilometer-api',
    }
  }

  firewall {'100 ceilometer':
    dport  => 8777,
    proto  => 'tcp',
    action => 'accept',
  }

}
class ceilometer::api::nagios-checks {
  # These are checks that can be run by the nagios server.
  nagios::command {
    'check_ceilometer':
      check_command => '/usr/lib/nagios/plugins/check_http -p \'$ARG1$\' -e 401 -H \'$HOSTADDRESS$\' -I \'$HOSTADDRESS$\'';
    'check_ceilometer_ssl':
      check_command => '/usr/lib/nagios/plugins/check_http --ssl -p \'$ARG1$\' -e 401 -H \'$HOSTADDRESS$\' -I \'$HOSTADDRESS$\'';
  }
}
