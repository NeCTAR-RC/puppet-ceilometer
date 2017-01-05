class ceilometer::agent-central inherits ceilometer {
  include ::ceilometer::agent_central

  notify {'class ceilometer::agent-central is deprecated. Please use ceilometer::agent_central': }
}
