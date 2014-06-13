class ceilometer($keystone_user,
                 $keystone_password,
                 $keystone_region=false,
                 $rabbit_hosts,
                 $rabbit_user,
                 $rabbit_password,
                 $rabbit_virtual_host,
                 $dispatchers='rpc',
                 $disable_local_storage='False',
                 $forward_metering_data='False',
                 $forwarder_transport_url=false,
                 $metering_secret,
                 $database_connection='sqlite:////var/lib/ceilometer/ceilometer.sqlite',
                 $logrotation='weekly',
                 $db_ttl=7776000,
)
{

  $openstack_version = hiera('openstack_version')
  $keystone_host = hiera('keystone::host')
  $keystone_protocol = hiera('keystone::protocol')
  $keystone_service_tenant = hiera('keystone::service_tenant')

  package {'ceilometer-common':
    ensure => installed
  }

  file {'ceilometer-config':
    path    => '/etc/ceilometer/ceilometer.conf',
    ensure  => present,
    content => template("ceilometer/${openstack_version}/ceilometer.conf.erb"),
    require => Package['ceilometer-common'],
  }

  logrotate::rule { 'ceilometer':
    ensure  => present,
    path    => '/var/log/ceilometer/*.log',
    options => [ 'rotate 4', $logrotation, 'missingok', 'compress', 'delaycompress', 'notifempty' ],
  }

  file { '/var/log/ceilometer':
    ensure  => directory,
    owner   => 'ceilometer',
    group   => 'ceilometer',
    mode    => '0750',
    require => Package['ceilometer-common'],
  }
}

class ceilometer::node inherits ceilometer {

  File['ceilometer-config'] {
    content => template("ceilometer/${openstack_version}/ceilometer-node.conf.erb"),
  }
}
