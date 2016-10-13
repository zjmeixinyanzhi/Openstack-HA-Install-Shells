#!/bin/sh
vip='192.168.2.201'
vip=$1
local_nic="eno16777736"
local_nic=$2
data_nic='eno50332184'
data_nic=$3
password=$4
 
echo $vip $local_nic $data_nic

yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
### [所有控制节点]配置neutron server，/etc/neutron/neutron.conf
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')

openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$password@$vip/neutron

openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $password

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$vip:35357
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password $password

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

### [所有控制节点]配置ML2 plugin，/etc/neutron/plugins/ml2/ml2_conf.ini
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan,gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver iptables_hybrid

### [所有控制节点]配置Open vSwitch agent，/etc/neutron/plugins/ml2/openvswitch_agent.ini，注意，此处填写第二块网卡

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $(ip addr show dev $data_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings external:br-ex

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True

### [所有控制节点]配置L3 agent，/etc/neutron/l3_agent.ini
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge

### [所有控制节点]配置DHCP agent，/etc/neutron/dhcp_agent.ini
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True

### [所有控制节点]配置metadata agent，/etc/neutron/metadata_agent.ini
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $vip
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $password

### [所有控制节点]配置nova和neutron集成，/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf neutron url http://$vip:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$vip:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $password

openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $password

### [所有控制节点]配置L3 agent HA、/etc/neutron/neutron.conf
openstack-config --set /etc/neutron/neutron.conf DEFAULT l3_ha True
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_automatic_l3agent_failover True
openstack-config --set /etc/neutron/neutron.conf DEFAULT max_l3_agents_per_router 3
openstack-config --set /etc/neutron/neutron.conf DEFAULT min_l3_agents_per_router 2

### [所有控制节点]配置DHCP agent HA、/etc/neutron/neutron.conf
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 3

### [所有控制节点] 配置Open vSwitch (OVS) 服务，创建网桥和端口
systemctl enable openvswitch.service
systemctl start openvswitch.service

### [所有控制节点] 创建ML2配置文件软连接
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
