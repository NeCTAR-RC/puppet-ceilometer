class ceilometer::agent-compute inherits ceilometer::node {
  include ::ceilometer::agent_compute

  notify {'class ceilometer::agent-compute is deprecated. Please use ceilometer::agent_compute': }
}
