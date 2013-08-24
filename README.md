sar-metrics
===========
Basic implementation of CloudWatch metrics for Openstack.
Supported metrics: CPUUtilization and MemoryUtilization.

Implementation is based on:
- sar util from sysstat package
- heat-watch util from heat-cfnclient repo: https://github.com/openstack-dev/heat-cfnclient

Scripts are written in ruby.
