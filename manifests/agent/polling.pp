# == Class: ceilometer::agent::polling
#
# Installs/configures the ceilometer polling agent
#
# === Parameters:
#
# [*enabled*]
#   (Optional) Should the service be enabled.
#   Defaults to true.
#
# [*manage_service*]
#   (Optional)  Whether the service should be managed by Puppet.
#   Defaults to true.
#
# [*package_ensure*]
#   (Optional) ensure state for package.
#   Defaults to 'present'
#
# [*manage_user*]
#   (Optional) Should the system user should be managed. When this flag is
#   true then the class ensures the ceilometer user belongs to nova/libvirt
#   group.
#   Defaults to true.
#
# [*central_namespace*]
#   (Optional) Use central namespace for polling agent.
#   Defaults to true.
#
# [*compute_namespace*]
#   (Optional) Use compute namespace for polling agent.
#   Defaults to true.
#
# [*ipmi_namespace*]
#   (Optional) Use ipmi namespace for polling agent.
#   Defaults to true.
#
# [*instance_discovery_method*]
#   (Optional) method to discovery instances running on compute node
#   Defaults to $::os_service_default
#    * naive: poll nova to get all instances
#    * workload_partitioning: poll nova to get instances of the compute
#    * libvirt_metadata: get instances from libvirt metadata
#      but without instance metadata (recommended for Gnocchi backend).
#
# [*resource_update_interval*]
#   (Optional) New instances will be discovered periodically based on this
#   option (in seconds).
#   Defaults to $::os_service_default.
#
# [*resource_cache_expiry*]
#   (Optional) The expiry to totally refresh the instances resource cache.
#   Defaults to $::os_service_default.
#
# [*manage_polling*]
#   (Optional) Whether to manage polling.yaml
#   Defaults to false
#
# [*polling_interval*]
#   (Optional) Number of seconds between polling cycle
#   Defaults to 600 seconds, used only if manage_polling is true.
#
# [*polling_meters*]
#   (Optional) Array of strings with meters to add to
#   the polling.yaml file, used only if manage_polling is true.
#   Defaults to $::ceilometer::params::polling_meters
#
# [*polling_config*]
#   (Optional) A hash of the polling.yaml configuration.
#   This is used only if manage_polling is true.
#   Defaults to undef
#
# [*batch_size*]
#   (Optional) Batch size of samples to send to notification agent.
#   Defaults to $::os_service_default
#
# [*tenant_name_discovery*]
#   (optional) Identify user and project names from polled metrics.
#   Defaults to $::os_service_default.
#
class ceilometer::agent::polling (
  $manage_service            = true,
  $enabled                   = true,
  $package_ensure            = 'present',
  $manage_user               = true,
  $central_namespace         = true,
  $compute_namespace         = true,
  $ipmi_namespace            = true,
  $objectstore_namespace     = false,
  $instance_discovery_method = $::os_service_default,
  $resource_update_interval  = $::os_service_default,
  $resource_cache_expiry     = $::os_service_default,
  $manage_polling            = false,
  $polling_interval          = 600,
  $polling_meters            = $::ceilometer::params::polling_meters,
  $polling_config            = undef,
  $batch_size                = $::os_service_default,
  $tenant_name_discovery     = $::os_service_default,
) inherits ceilometer {

  include ceilometer::deps
  include ceilometer::params

  if $central_namespace {
    $central_namespace_name = 'central'
    ceilometer_config {
      # set `tenant_name_discovery` parameter only on the nodes
      # where central namespace is enabled
      'DEFAULT/tenant_name_discovery': value => $tenant_name_discovery;
    }
  } else {
    $central_namespace_name = undef
    ceilometer_config {
      'DEFAULT/tenant_name_discovery': ensure => absent;
    }
  }

  if $compute_namespace {
    if $manage_user {
      # The ceilometer user created by the ceilometer-common package does not
      # belong to nova/libvirt group. That group membership is required so that
      # the ceilometer user can access libvirt to gather some metrics.
      $ceilometer_groups = delete_undef_values([
        'nova',
        $::ceilometer::params::libvirt_group
      ])

      user { 'ceilometer':
        ensure  => present,
        name    => 'ceilometer',
        gid     => 'ceilometer',
        groups  => $ceilometer_groups,
        require => Anchor['ceilometer::install::end'],
        before  => Anchor['ceilometer::service::begin'],
      }

      if $::ceilometer::params::libvirt_group {
        Package <| title == 'libvirt' |> -> User['ceilometer']
      }
      Package <| title == 'nova-common' |> -> User['ceilometer']

      User['ceilometer'] -> Anchor['ceilometer::service::begin']
    }

    $compute_namespace_name = 'compute'
    ceilometer_config {
      'compute/instance_discovery_method': value => $instance_discovery_method;
      'compute/resource_update_interval':  value => $resource_update_interval;
      'compute/resource_cache_expiry':     value => $resource_cache_expiry;
    }
  } else {
    $compute_namespace_name = undef
    ceilometer_config {
      'compute/instance_discovery_method': ensure => absent;
      'compute/resource_update_interval':  ensure => absent;
      'compute/resource_cache_expiry':     ensure => absent;
    }
  }

  if $ipmi_namespace {
    $ipmi_namespace_name = 'ipmi'
  } else {
    $ipmi_namespace_name = undef
  }

  if $objectstore_namespace {
    $objectstore_namespace_name = 'objectstore'
  } else {
    $objectstore_namespace_name = ''
  }

  package { 'ceilometer-polling':
    ensure => $package_ensure,
    name   => $::ceilometer::params::agent_polling_package_name,
    tag    => ['openstack', 'ceilometer-package'],
  }

  $namespaces_real = delete_undef_values([
    $central_namespace_name,
    $compute_namespace_name,
    $ipmi_namespace_name,
    $objectstore_namespace_name
  ])

  if empty($namespaces_real) {
    ceilometer_config {
      'DEFAULT/polling_namespaces': ensure => absent
    }
  } else {
    ceilometer_config {
      'DEFAULT/polling_namespaces': value => join($namespaces_real, ',')
    }
  }

  ceilometer_config {
    'polling/batch_size': value => $batch_size
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }

    service { 'ceilometer-polling':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::agent_polling_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      tag        => 'ceilometer-service',
    }
  }

  if $manage_polling {
    if $polling_config {
      validate_legacy(Hash, 'validate_hash', $polling_config)
      $polling_content = to_yaml($polling_config)
    } else {
      $polling_content = template('ceilometer/polling.yaml.erb')
    }

    file { 'polling':
      ensure                  => present,
      path                    => $::ceilometer::params::polling,
      content                 => $polling_content,
      mode                    => '0640',
      owner                   => 'root',
      group                   => $::ceilometer::params::group,
      selinux_ignore_defaults => true,
      tag                     => 'ceilometer-yamls',
    }
  }
}
