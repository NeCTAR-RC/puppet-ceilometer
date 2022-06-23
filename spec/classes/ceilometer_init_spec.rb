require 'spec_helper'

describe 'ceilometer' do

  let :params do
    {
      :http_timeout          => '600',
      :telemetry_secret      => 'metering-s3cr3t',
      :package_ensure        => 'present',
      :purge_config          => false,
      :host                  => 'foo.domain'
    }
  end

  let :rabbit_params do
    {
      :rabbit_qos_prefetch_count => 10,
    }
  end

  shared_examples_for 'ceilometer' do

    it 'configures timeout for HTTP requests' do
      is_expected.to contain_ceilometer_config('DEFAULT/http_timeout').with_value(params[:http_timeout])
    end

    it 'configures host name' do
      is_expected.to contain_ceilometer_config('DEFAULT/host').with_value(params[:host])
    end

    context 'with rabbit parameters' do
      before { params.merge!( rabbit_params ) }
      it_configures 'a ceilometer base installation'
      it_configures 'rabbit with SSL support'
      it_configures 'rabbit without HA support (with backward compatibility)'
      it_configures 'rabbit with connection heartbeats'

      context 'with rabbit_ha_queues' do
        before { params.merge!( rabbit_params ).merge!( :rabbit_ha_queues => true ) }
        it_configures 'rabbit with rabbit_ha_queues'
       end

    end

    context 'with rabbit parameters' do
      context 'with one server' do
        before { params.merge!( rabbit_params ) }
        it_configures 'a ceilometer base installation'
        it_configures 'rabbit with SSL support'
        it_configures 'rabbit without HA support (without backward compatibility)'
      end

    end

    context 'with amqp messaging' do
      it_configures 'amqp support'
    end

  end

  shared_examples_for 'a ceilometer base installation' do

    it { is_expected.to contain_class('ceilometer::params') }

    it 'installs ceilometer common package' do
      is_expected.to contain_package('ceilometer-common').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name],
        :tag    => ['openstack', 'ceilometer-package'],
      )
    end

    it 'passes purge to resource' do
      is_expected.to contain_resources('ceilometer_config').with({
        :purge => false
      })
    end

    it 'configures required telemetry_secret' do
      is_expected.to contain_ceilometer_config('publisher/telemetry_secret').with_value('metering-s3cr3t')
      is_expected.to contain_ceilometer_config('publisher/telemetry_secret').with_value( params[:telemetry_secret] ).with_secret(true)
    end

    context 'without the required telemetry_secret' do
      before { params.delete(:telemetry_secret) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    it 'configures default transport_url' do
      is_expected.to contain_ceilometer_config('DEFAULT/executor_thread_pool_size').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('DEFAULT/transport_url').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('DEFAULT/rpc_response_timeout').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('DEFAULT/control_exchange').with_value('<SERVICE DEFAULT>')
    end

    it 'configures notifications' do
      is_expected.to contain_ceilometer_config('oslo_messaging_notifications/topics').with_value('notifications')
      is_expected.to contain_ceilometer_config('oslo_messaging_notifications/driver').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('oslo_messaging_notifications/transport_url').with_value('<SERVICE DEFAULT>')
    end

    it 'configures snmpd auth' do
      is_expected.to contain_ceilometer_config('hardware/readonly_user_name').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('hardware/readonly_user_password').with_value('<SERVICE DEFAULT>').with_secret(true)
    end

    it 'configures cache backend' do
      is_expected.to contain_oslo__cache('ceilometer_config').with(
        :backend                => '<SERVICE DEFAULT>',
        :memcache_servers       => '<SERVICE DEFAULT>',
        :tls_enabled            => '<SERVICE DEFAULT>',
        :tls_cafile             => '<SERVICE DEFAULT>',
        :tls_certfile           => '<SERVICE DEFAULT>',
        :tls_keyfile            => '<SERVICE DEFAULT>',
        :tls_allowed_ciphers    => '<SERVICE DEFAULT>',
        :manage_backend_package => true,
      )
    end

    context 'with rabbitmq durable queues configured' do
      before { params.merge!( :amqp_durable_queues => true ) }
      it_configures 'rabbit with durable queues'
    end

    context 'with overridden transport_url parameter' do
      before {
        params.merge!(
          :executor_thread_pool_size => '128',
          :default_transport_url     => 'rabbit://rabbit_user:password@localhost:5673',
          :rpc_response_timeout      => '120',
          :control_exchange          => 'ceilometer',
        )
      }

      it 'configures transport_url' do
        is_expected.to contain_ceilometer_config('DEFAULT/executor_thread_pool_size').with_value('128')
        is_expected.to contain_ceilometer_config('DEFAULT/transport_url').with_value('rabbit://rabbit_user:password@localhost:5673')
        is_expected.to contain_ceilometer_config('DEFAULT/rpc_response_timeout').with_value('120')
        is_expected.to contain_ceilometer_config('DEFAULT/control_exchange').with_value('ceilometer')
      end
    end

    context 'with overridden cache parameter' do
      before {
        params.merge!(
          :cache_backend          => 'memcache',
          :memcache_servers       => 'host1:11211,host2:11211',
          :cache_tls_enabled      => true,
          :manage_backend_package => false,
        )
      }

      it 'configures cache backend' do
        is_expected.to contain_oslo__cache('ceilometer_config').with(
          :backend                => 'memcache',
          :memcache_servers       => 'host1:11211,host2:11211',
          :tls_enabled            => true,
          :manage_backend_package => false,
        )
      end
    end

    context 'with overridden notification parameters' do
      before {
        params.merge!(
          :notification_topics        => ['notifications', 'custom'],
          :notification_driver        => 'messagingv1',
          :notification_transport_url => 'rabbit://rabbit_user:password@localhost:5673',
        )
      }

      it 'configures notifications' do
        is_expected.to contain_ceilometer_config('oslo_messaging_notifications/topics').with_value('notifications,custom')
        is_expected.to contain_ceilometer_config('oslo_messaging_notifications/driver').with_value('messagingv1')
        is_expected.to contain_ceilometer_config('oslo_messaging_notifications/transport_url').with_value('rabbit://rabbit_user:password@localhost:5673')
      end
    end
  end

  shared_examples_for 'rabbit without HA support (with backward compatibility)' do

    it 'configures rabbit' do
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_rate').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_in_pthread').with_value('<SERVICE DEFAULT>')
    end

    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_qos_prefetch_count').with_value( params[:rabbit_qos_prefetch_count] ) }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('<SERVICE DEFAULT>') }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_failover_strategy').with_value('<SERVICE DEFAULT>') }

  end

  shared_examples_for 'rabbit without HA support (without backward compatibility)' do

    it 'configures rabbit' do
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_rate').with_value('<SERVICE DEFAULT>')
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_in_pthread').with_value('<SERVICE DEFAULT>')
    end

    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_qos_prefetch_count').with_value( params[:rabbit_qos_prefetch_count] ) }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value('<SERVICE DEFAULT>') }
    it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/kombu_failover_strategy').with_value('<SERVICE DEFAULT>') }

  end

  shared_examples_for 'rabbit with rabbit_ha_queues' do

    it 'configures rabbit' do
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value( params[:rabbit_ha_queues] )
    end
  end

  shared_examples_for 'rabbit with durable queues' do
    it 'in ceilometer' do
      is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/amqp_durable_queues').with_value(true)
    end
  end

  shared_examples_for 'rabbit with connection heartbeats' do
    context "with heartbeat configuration" do
      before { params.merge!(
        :rabbit_heartbeat_timeout_threshold => '60',
        :rabbit_heartbeat_rate              => '10',
        :rabbit_heartbeat_in_pthread        => true,
      ) }

      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_timeout_threshold').with_value('60') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_rate').with_value('10') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_rabbit/heartbeat_in_pthread').with_value(true) }
    end
  end


  # Cleanup in Ocata
  shared_examples_for 'using old metering_secret param' do
    context "with old metering_secret param it uses telemetry_secret instead" do
      before { params.merge!(
          :metering_secret => 'broncos',
          :telemetry_secret => 'metering-s3cr3t',
      ) }
      it { is_expected.to contain_ceilometer_config('publisher/telemetry_secret').with_value('metering-s3cr3t') }
    end
    context "with old metering_secret param set and telemetry_secret unset" do
      before { params.merge!(
          :metering_secret => 'broncos',
          :telemetry_secret => nil,
      ) }
      it { is_expected.to contain_ceilometer_config('publisher/telemetry_secret').with_value('broncos') }
    end
  end

  shared_examples_for 'rabbit with SSL support' do
    context "with default parameters" do
    it { is_expected.to contain_oslo__messaging__rabbit('ceilometer_config').with(
      :rabbit_use_ssl     => '<SERVICE DEFAULT>',
      :kombu_ssl_ca_certs => '<SERVICE DEFAULT>',
      :kombu_ssl_certfile => '<SERVICE DEFAULT>',
      :kombu_ssl_keyfile  => '<SERVICE DEFAULT>',
      :kombu_ssl_version  => '<SERVICE DEFAULT>',
    )}
    end

    context "with SSL enabled with kombu" do
      before { params.merge!(
        :rabbit_use_ssl     => true,
        :kombu_ssl_ca_certs => '/path/to/ca.crt',
        :kombu_ssl_certfile => '/path/to/cert.crt',
        :kombu_ssl_keyfile  => '/path/to/cert.key',
        :kombu_ssl_version  => 'TLSv1'
      ) }

    it { is_expected.to contain_oslo__messaging__rabbit('ceilometer_config').with(
      :rabbit_use_ssl     => true,
      :kombu_ssl_ca_certs => '/path/to/ca.crt',
      :kombu_ssl_certfile => '/path/to/cert.crt',
      :kombu_ssl_keyfile  => '/path/to/cert.key',
      :kombu_ssl_version  => 'TLSv1'
    )}
    end

    context "with SSL enabled without kombu" do
      before { params.merge!(
        :rabbit_use_ssl  => true
      ) }

    it { is_expected.to contain_oslo__messaging__rabbit('ceilometer_config').with(
      :rabbit_use_ssl     => true,
    )}
    end

    context "with SSL wrongly configured" do
      context 'with kombu_ssl_ca_certs parameter' do
        before { params.merge!(:kombu_ssl_ca_certs => '/path/to/ca.crt') }
        it_raises 'a Puppet::Error', /The kombu_ssl_ca_certs parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with kombu_ssl_certfile parameter' do
        before { params.merge!(:kombu_ssl_certfile => '/path/to/ssl/cert/file') }
        it_raises 'a Puppet::Error', /The kombu_ssl_certfile parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with kombu_ssl_keyfile parameter' do
        before { params.merge!(:kombu_ssl_keyfile => '/path/to/ssl/keyfile') }
        it_raises 'a Puppet::Error', /The kombu_ssl_keyfile parameter requires rabbit_use_ssl to be set to true/
      end
    end
  end

  shared_examples_for 'amqp support' do
    context 'with default parameters' do
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/server_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/broadcast_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/group_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/container_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/idle_timeout').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/trace').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/ssl_ca_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/ssl_cert_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/ssl_key_file').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/ssl_key_password').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/sasl_mechanisms').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/sasl_config_dir').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/sasl_config_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/username').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/password').with_value('<SERVICE DEFAULT>') }
    end

    context 'with overridden amqp parameters' do
      before { params.merge!(
        :amqp_idle_timeout  => '60',
        :amqp_trace         => true,
        :amqp_ssl_ca_file   => '/path/to/ca.cert',
        :amqp_ssl_cert_file => '/path/to/certfile',
        :amqp_ssl_key_file  => '/path/to/key',
        :amqp_username      => 'amqp_user',
        :amqp_password      => 'password',
      ) }

      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/server_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/broadcast_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/group_request_prefix').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/container_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/idle_timeout').with_value('60') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/trace').with_value('true') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/ssl_ca_file').with_value('/path/to/ca.cert') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/ssl_cert_file').with_value('/path/to/certfile') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/ssl_key_file').with_value('/path/to/key') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/sasl_mechanisms').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/sasl_config_dir').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/sasl_config_name').with_value('<SERVICE DEFAULT>') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/username').with_value('amqp_user') }
      it { is_expected.to contain_ceilometer_config('oslo_messaging_amqp/password').with_value('password') }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      let :platform_params do
        case facts[:osfamily]
        when 'Debian'
          { :common_package_name => 'ceilometer-common' }
        when 'RedHat'
          { :common_package_name => 'openstack-ceilometer-common' }
        end
      end

      it_behaves_like 'ceilometer'
    end
  end

end
