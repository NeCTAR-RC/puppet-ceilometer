# Configures the ceilometer-api service with UWSGI.
#
class ceilometer::api::uwsgi($workers=1) inherits ceilometer::api {

  include uwsgi

  $worker_name = 'uwsgi-worker-ceilometer-api'
  $wsgi_file = '/etc/ceilometer/app.wsgi'

  Service['ceilometer-api'] {
    ensure => 'stopped',
  }

  file {$wsgi_file:
    source => "puppet:///modules/ceilometer/${ceilometer::api::openstack_version}/app.wsgi",
    owner  => 'ceilometer',
    group  => 'ceilometer',
  }

  uwsgi::manage_app {'ceilometer-api':
    ensure => 'present',
    uid    => 'ceilometer',
    gid    => 'ceilometer',
    config => {
      http-socket     => ':8777',
      master          => true,
      plugin          => 'python',
      enable-threads  => true,
      need-app        => true,
      buffer-size     => '16384',
      timeout         => '300',
      pecan           => $wsgi_file,
      processes       => $workers,
      procname        => $worker_name,
      procname-master => 'uwsgi-master-ceilometer-api',
    }
  }

  Nagios::Nrpe::Service['service_ceilometer_api'] {
    check_command => "/usr/lib/nagios/plugins/check_procs -c ${workers}:${workers} -u ceilometer -a ${worker_name}",
  }

}
