class ceilometer::agent-notification inherits ceilometer {
  include ::ceilometer::agent_notification

  notify {'class ceilometer::agent-notification is deprecated. Please use ceilometer::agent_notification': }
}
