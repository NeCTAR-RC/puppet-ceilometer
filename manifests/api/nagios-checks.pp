# Keep backwards compatability. Remove when everyone migrates to the new class
class ceilometer::api::nagios-checks {
    include ::nectar::nagios::ceilometer

    notify {'class ceilometer::api::nagios-checks is deprecated. Please use ceilometer::api::nagios_checks': }
}
