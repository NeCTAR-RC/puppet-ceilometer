class ceilometer::alarm-notifier inherits ceilometer {
  include ::ceilometer::alarm_notifier

  notify {'class ceilometer::alarm-notifier is deprecated. Please use ceilometer::alarm_notifier': }
}
