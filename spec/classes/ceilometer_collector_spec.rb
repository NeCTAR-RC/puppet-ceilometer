require 'spec_helper'

describe 'ceilometer::collector' do

  let :pre_condition do
    "class { 'ceilometer': telemetry_secret => 's3cr3t' }"
  end

  shared_examples_for 'ceilometer-collector' do

    context 'when invalid ip is passed' do
      let :params do
        { :udp_address => '300.0.0.0' }
      end
      it 'should fail' do
        is_expected.to raise_error(Puppet::Error, /is not a valid ip and is not empty/)
      end
    end

    context 'when a valid ipv6 is passed' do
      before do
        pre_condition << "class { 'ceilometer::db': }"
      end
      let :params do
        { :udp_address => '::1' }
      end
      it 'shouldn\'t fail' do
        is_expected.to_not raise_error
      end
    end

    context 'when an empty string passed' do
      before do
        pre_condition << "class { 'ceilometer::db': }"
      end
      let :params do
        { :udp_address => '' }
      end
      it 'should disable the listener' do
        is_expected.to contain_ceilometer_config('collector/udp_address').with_value( '' )
      end
    end

    context 'when enabled' do
      before do
        pre_condition << "class { 'ceilometer::db': }"
      end

      it { is_expected.to contain_class('ceilometer::params') }

      it 'configures ceilometer-collector server' do
        is_expected.to contain_ceilometer_config('collector/udp_address').with_value( '0.0.0.0' )
        is_expected.to contain_ceilometer_config('collector/udp_port').with_value( '4952' )
        is_expected.to contain_ceilometer_config('collector/workers').with_value('<SERVICE DEFAULT>')
        is_expected.to contain_ceilometer_config('DEFAULT/meter_dispatchers').with_value( ['database'] )
        is_expected.to contain_ceilometer_config('DEFAULT/event_dispatchers').with_value( ['database'] )
      end

      it 'installs ceilometer-collector package' do
        is_expected.to contain_package(platform_params[:collector_package_name]).with(
          :ensure => 'present'
        )
      end

      it 'configures ceilometer-collector service' do
        is_expected.to contain_service('ceilometer-collector').with(
          :ensure     => 'running',
          :name       => platform_params[:collector_service_name],
          :enable     => true,
          :hasstatus  => true,
          :hasrestart => true,
          :tag        => 'ceilometer-service'
        )
      end

    end

    context 'when disabled' do
      let :params do
        { :enabled => false }
      end

      # Catalog compilation does not crash for lack of ceilometer::db
      it { is_expected.to compile }
      it 'configures ceilometer-collector service' do
        is_expected.to contain_service('ceilometer-collector').with(
          :ensure     => 'stopped',
          :name       => platform_params[:collector_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true,
          :tag        => 'ceilometer-service'
        )
      end
    end

    context 'when service management is disabled' do
      let :params do
        { :enabled        => false,
          :manage_service => false }
      end

      it 'configures ceilometer-collector service' do
        is_expected.to contain_service('ceilometer-collector').with(
          :ensure     => nil,
          :name       => platform_params[:collector_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true,
          :tag        => 'ceilometer-service'
        )
      end
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
          { :collector_package_name => 'ceilometer-collector',
            :collector_service_name => 'ceilometer-collector' }
        when 'RedHat'
          { :collector_package_name => 'openstack-ceilometer-collector',
            :collector_service_name => 'openstack-ceilometer-collector' }
        end
      end

      it_behaves_like 'ceilometer-collector'
    end
  end

end
