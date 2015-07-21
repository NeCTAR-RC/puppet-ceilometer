# Set up a dev ceilometer env
class ceilometer::develop (
  $git_url='https://github.com/NeCTAR-RC/ceilometer.git',
  $branch='nectar/juno') inherits ceilometer {

  #include ceilometer::develop::api
  #include ceilometer::develop::collector
  #include ceilometer::develop::agent-central

  Package['ceilometer-common'] {
    ensure => absent,
  }
  #exec {"virtualenv /opt/${ceilometer::openstack_version}":
  #  path    => '/usr/bin',
  #  creates => "/opt/${ceilometer::openstack_version}/bin/activate",
  #}

  git::clone { 'ceilometer':
    git_repo        => $git_url,
    projectroot     => '/opt/ceilometer',
    cloneddir_user  => 'ceilometer',
    cloneddir_group => 'ceilometer',
    branch          => $branch,
  }

  exec {'pip-install-ceilometer':
    command => 'pip install -e .',
    cwd     => '/opt/ceilometer/',
    path    => "/opt/${ceilometer::openstack_version}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    creates => '/opt/juno/bin/ceilometer-dbsync ',
    timeout => 3600,
    require => Git::Clone['ceilometer'],
  }
  exec {'pip install pymongo':
    cwd     => '/opt/ceilometer/',
    path    => "/opt/${ceilometer::openstack_version}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    creates => "/opt/${ceilometer::openstack_version}/lib/python2.7/site-packages/pymongo",
    timeout => 3600,
    require => Git::Clone['ceilometer'],
  }

  file {['/etc/ceilometer', '/var/lib/ceilometer']:
    ensure => directory,
    owner  => ceilometer,
    group  => ceilometer,
    mode   => '0755',
  }

  user {'ceilometer':
    home => '/var/lib/ceilometer',
  }

  file { '/etc/ceilometer/api_paste.ini':
    ensure => link,
    target => '/opt/ceilometer/etc/ceilometer/api_paste.ini',
  }

  file { '/etc/ceilometer/pipeline.yaml':
    ensure => link,
    target => '/opt/ceilometer/etc/ceilometer/pipeline.yaml',
  }

  file { '/etc/ceilometer/event_definitions.yaml':
    ensure => link,
    target => '/opt/ceilometer/etc/ceilometer/event_definitions.yaml',
  }

  file { '/etc/ceilometer/rootwrap.conf':
    ensure => link,
    target => '/opt/ceilometer/etc/ceilometer/rootwrap.conf',
  }

  file { '/etc/ceilometer/rootwrap.d':
    ensure => link,
    target => '/opt/ceilometer/etc/ceilometer/rootwrap.d',
  }

  file {'/usr/local/bin/ceilometer-rootwrap':
    ensure => link,
    target => "/opt/${ceilometer::openstack_version}/bin/ceilometer-rootwrap",
  }

}

class ceilometer::develop::api inherits ceilometer::api {

  Package['ceilometer-api'] {
    ensure => absent,
  }

  Service['ceilometer-api'] {
    ensure   => running,
    provider => upstart,
  }

  file {'/usr/local/bin/ceilometer-api':
    ensure => link,
    target => "/opt/${ceilometer::openstack_version}/bin/ceilometer-api",
  }

  file {'/etc/init/ceilometer-api.conf':
    source => 'puppet:///modules/ceilometer/api-init.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }


}

class ceilometer::develop::collector($rpc_transport_url=undef, $rabbit_virtual_host=undef) inherits ceilometer::collector {
  Package['ceilometer-collector'] {
    ensure => absent,
  }

  Service['ceilometer-collector'] {
    provider => upstart,
  }

  file {'/usr/local/bin/ceilometer-collector':
    ensure => link,
    target => "/opt/${ceilometer::openstack_version}/bin/ceilometer-collector",
  }

  file {'/etc/init/ceilometer-collector.conf':
    source => 'puppet:///modules/ceilometer/collector-init.conf',
  }

}

class ceilometer::develop::collector::cell (
    $rpc_transport_url,
    $rabbit_virtual_host
) inherits ceilometer {


  file {'ceilometer-config-cell':
    ensure  => present,
    path    => '/etc/ceilometer/ceilometer-cell.conf',
    content => template("ceilometer/${ceilometer::openstack_version}/ceilometer-cell.conf.erb"),
    require => Package['ceilometer-common'],
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  service {'ceilometer-collector-cell':
    ensure    => running,
    subscribe => File['ceilometer-config-cell'],
    require   => Package['ceilometer-collector'],
    provider  => upstart,
  }

  file {'/etc/init/ceilometer-collector-cell.conf':
    source => 'puppet:///modules/ceilometer/collector-cell-init.conf',
  }

}

class ceilometer::develop::agent-central inherits ceilometer::agent-central {

  Package['ceilometer-agent-central'] {
    ensure => absent,
  }

  Service['ceilometer-agent-central'] {
    provider => upstart,
  }

  file {'/usr/local/bin/ceilometer-agent-central':
    ensure => link,
    target => "/opt/${ceilometer::openstack_version}/bin/ceilometer-agent-central",
  }

  file {'/etc/init/ceilometer-agent-central.conf':
    source => 'puppet:///modules/ceilometer/agent-central-init.conf',
  }

}

class ceilometer::develop::agent-notification inherits ceilometer::agent-notification {

  Package['ceilometer-agent-notification'] {
    ensure => absent,
  }

  Service['ceilometer-agent-notification'] {
    provider => upstart,
  }

  file {'/usr/local/bin/ceilometer-agent-notification':
    ensure => link,
    target => "/opt/${ceilometer::openstack_version}/bin/ceilometer-agent-notification",
  }

  file {'/etc/init/ceilometer-agent-notification.conf':
    source => 'puppet:///modules/ceilometer/agent-notification-init.conf',
  }

}

class ceilometer::develop::agent-notification::cell inherits ceilometer {

  service {'ceilometer-agent-notification-cell':
    ensure    => running,
    subscribe => File['ceilometer-config-cell'],
    provider  => upstart,
  }

  file {'/etc/init/ceilometer-agent-notification-cell.conf':
    source => 'puppet:///modules/ceilometer/agent-notification-cell.conf',
  }

}

class ceilometer::develop::agent-compute inherits ceilometer::agent-compute {


  Package['ceilometer-agent-compute'] {
    ensure => absent,
  }

  Service['ceilometer-agent-compute'] {
    provider => upstart,
  }

  file {'/usr/local/bin/ceilometer-agent-compute':
    ensure => link,
    target => "/opt/${ceilometer::openstack_version}/bin/ceilometer-agent-compute",
  }

  file {'/etc/init/ceilometer-agent-compute.conf':
    source => 'puppet:///modules/ceilometer/agent-compute-init.conf',
  }

}
