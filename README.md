======================================
Puppet Ceilometer module for NeCTAR RC
======================================

Variables
=========

This module makes explicit use of hiera, you will need it to use this
module.

Example:
--------

```yaml
ceilometer::keystone_region: <region>
ceilometer::keystone_user: <username>
ceilometer::keystone_password: <password>
ceilometer::rabbit_hosts: 'rabbit.test:5671'
ceilometer::rabbit_user: <username>
ceilometer::rabbit_password: <password>
ceilometer::rabbit_virtual_host: compute
ceilometer::mongodb_host: localhost
```

Classes
=======

ceilometer
----------

ceilometer::collector
---------------------
Processes data from the Ceilometer queue and adds it to the DB.

ceilometer::api
---------------
The API interface to Ceilometer

ceilometer::agent-compute
-------------------------
Installed the compute agent, for use on a compute node.


Other variables needed
======================

 * keystone::host
 * keystone::protocol
 * keystone::service_tenant

 * swift::protocol
 * nfs::options
