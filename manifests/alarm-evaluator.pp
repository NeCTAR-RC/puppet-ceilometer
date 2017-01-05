class ceilometer::alarm-evaluator inherits ceilometer {
  include ::ceilometer::alarm_evaluator

  notify {'class ceilometer::alarm-evaluator is deprecated. Please use ceilometer::alarm_evaluator': }
}
