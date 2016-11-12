#!/bin/sh
pcs resource op add neutron-scale start timeout=300
pcs resource op add neutron-scale stop timeout=300
pcs resource op add neutron-ovs-cleanup start timeout=300
pcs resource op add neutron-ovs-cleanup stop timeout=300
pcs resource op add neutron-netns-cleanup start timeout=300
pcs resource op add neutron-netns-cleanup stop timeout=300
pcs resource op add neutron-openvswitch-agent start timeout=300
pcs resource op add neutron-openvswitch-agent stop timeout=300
pcs resource op add neutron-dhcp-agent start timeout=300
pcs resource op add neutron-dhcp-agent stop timeout=300
pcs resource op add neutron-l3-agent start timeout=300
pcs resource op add neutron-l3-agent stop timeout=300
pcs resource op add neutron-metadata-agent start timeout=300
pcs resource op add neutron-metadata-agent stop timeout=300