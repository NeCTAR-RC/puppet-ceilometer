# Ceilometer base class
class ceilometer(
  $keystone_user,
  $keystone_password,
  $keystone_region=false,
  $rabbit_hosts,
  $rabbit_user,
  $rabbit_password,
  $rabbit_virtual_host,
  $dispatchers='rpc',
  $collector_workers=1,
  $disable_local_storage='False',
  $forward_metering_data='False',
  $forwarder_transport_url=false,
  $metering_secret,
  $default_source_interval=600,
  $cpu_source_interval=600,
  $disk_source_interval=600,
  $network_source_interval=600,
  $database_connection='sqlite:////var/lib/ceilometer/ceilometer.sqlite',
  $logrotation='weekly',
  $db_ttl=7776000,
  $agent_hostname=$::hostname,
  $alarm_db_connection=undef,
  $gnocchi_url=undef,
)
{

  $openstack_version = hiera('openstack_version')
  $keystone_host = hiera('keystone::host')
  $keystone_protocol = hiera('keystone::protocol')
  $keystone_service_tenant = hiera('keystone::service_tenant')

  package {['ceilometer-common', 'python-pymongo']:
    ensure => installed
  }

  file {'ceilometer-config':
    ensure  => present,
    path    => '/etc/ceilometer/ceilometer.conf',
    owner   => 'ceilometer',
    group   => 'ceilometer',
    mode    => '0644',
    content => template("ceilometer/${openstack_version}/ceilometer.conf.erb"),
    require => Package['ceilometer-common'],
  }

  file {'ceilometer-pipeline.yaml':
    ensure  => present,
    path    => '/etc/ceilometer/pipeline.yaml',
    owner   => 'ceilometer',
    group   => 'ceilometer',
    mode    => '0644',
    content => template("ceilometer/${openstack_version}/pipeline.yaml.erb"),
    require => Package['ceilometer-common'],
  }

  $logrotate_rule = $openstack_version ? {
    'icehouse' => 'ceilometer',
    default    => 'ceilometer-common',
  }

  logrotate::rule { $logrotate_rule:
    ensure  => present,
    path    => '/var/log/ceilometer/*.log',
    options => ['rotate 4', $logrotation, 'missingok',
                'compress', 'delaycompress', 'notifempty'],
  }

  if $logrotate_rule == 'ceilometer-common' {
    logrotate::rule {'ceilometer':
      ensure => absent,
    }
  }

  file { '/var/log/ceilometer':
    ensure  => directory,
    owner   => 'ceilometer',
    group   => 'adm',
    mode    => '0750',
    require => Package['ceilometer-common'],
  }

  if $gnocchi_url {

    file {'/etc/ceilometer/gnocchi_resources.yaml':
      ensure  => present,
      owner   => 'ceilometer',
      group   => 'ceilometer',
      mode    => '0644',
      source  => "puppet:///modules/ceilometer/${openstack_version}/gnocchi_resources.yaml",
      require => Package['ceilometer-common'],
    }
  }
}

class ceilometer::node inherits ceilometer {

  File['ceilometer-config'] {
    content => template("ceilometer/${openstack_version}/ceilometer-node.conf.erb"),
  }
}
