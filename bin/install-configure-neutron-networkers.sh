#!/bin/sh
#####[所有网络节点] 安装neutron 
./pssh-exe N "yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch"
### [所有网络节点]配置neutron server
for ((i=0; i<${#networker_map[@]}; i+=1));
do
  name=${networker_name[$i]};
  ip=${networker_map[$name]};
  . style/print-info.sh "Openstack configure in $name"
  data_ip=$(ssh $ip cat /etc/sysconfig/network-scripts/ifcfg-$data_nic |grep IPADDR=|egrep -v "#IPADDR"|awk -F "=" '{print $2}')
  ssh root@$ip /bin/bash << EOF
  openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $ip
  openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$password@$virtual_ip/neutron
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
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$virtual_ip:5000
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$virtual_ip:35357
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
  openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $password
  openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
  openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
  openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$virtual_ip:35357
  openstack-config --set /etc/neutron/neutron.conf nova auth_type password
  openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
  openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
  openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
  openstack-config --set /etc/neutron/neutron.conf nova project_name service
  openstack-config --set /etc/neutron/neutron.conf nova username nova
  openstack-config --set /etc/neutron/neutron.conf nova password $password
  openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan,gre
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
  openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver iptables_hybrid
  openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
  openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
  openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid
  openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $data_ip
  openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings external:br-ex
  openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
  openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True
  openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge
  openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
  openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
  openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
  openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $virtual_ip
  openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $password
  openstack-config --set /etc/neutron/neutron.conf DEFAULT l3_ha True
  openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_automatic_l3agent_failover True
  openstack-config --set /etc/neutron/neutron.conf DEFAULT max_l3_agents_per_router 3
  openstack-config --set /etc/neutron/neutron.conf DEFAULT min_l3_agents_per_router 2
  openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 3
  systemctl enable openvswitch.service
  systemctl start openvswitch.service
  ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
EOF
done;
### [任一网络节点]添加pacemaker资源
ssh root@$network_host /bin/bash << EOF
  pcs resource create neutron-scale ocf:neutron:NeutronScale --clone globally-unique=true clone-max=3 interleave=true
  pcs resource create neutron-ovs-cleanup ocf:neutron:OVSCleanup --clone interleave=true
  pcs resource create neutron-netns-cleanup ocf:neutron:NetnsCleanup --clone interleave=true
  pcs resource create neutron-openvswitch-agent systemd:neutron-openvswitch-agent --clone interleave=true
  pcs resource create neutron-dhcp-agent systemd:neutron-dhcp-agent --clone interleave=true
  pcs resource create neutron-l3-agent systemd:neutron-l3-agent --clone interleave=true
  pcs resource create neutron-metadata-agent systemd:neutron-metadata-agent  --clone interleave=true
  pcs constraint order start neutron-scale-clone then neutron-ovs-cleanup-clone
  pcs constraint colocation add neutron-ovs-cleanup-clone with neutron-scale-clone
  pcs constraint order start neutron-ovs-cleanup-clone then neutron-netns-cleanup-clone
  pcs constraint colocation add neutron-netns-cleanup-clone with neutron-ovs-cleanup-clone
  pcs constraint order start neutron-netns-cleanup-clone then neutron-openvswitch-agent-clone
  pcs constraint colocation add neutron-openvswitch-agent-clone with neutron-netns-cleanup-clone
  pcs constraint order start neutron-openvswitch-agent-clone then neutron-dhcp-agent-clone
  pcs constraint colocation add neutron-dhcp-agent-clone with neutron-openvswitch-agent-clone
  pcs constraint order start neutron-dhcp-agent-clone then neutron-l3-agent-clone
  pcs constraint colocation add neutron-l3-agent-clone with neutron-dhcp-agent-clone
  pcs constraint order start neutron-l3-agent-clone then neutron-metadata-agent-clone
  pcs constraint colocation add neutron-metadata-agent-clone with neutron-l3-agent-clone
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
EOF
###[所有网络节点] ovs 操作
echo "ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex "$local_nic
tag=`eval date +%Y%m%d%H%M%S`
for ((i=0; i<${#networker_map[@]}; i+=1));
do
  name=${networker_name[$i]};
  ip=${networker_map[$name]};
  echo "-------------$name------------"
  \cp ../conf/ifcfg-br-ex.template ../conf/ifcfg-br-ex
  \cp ../conf/ifcfg-local_nic.template ../conf/ifcfg-local_nic
  ssh $ip cp /etc/sysconfig/network-scripts/ifcfg-$local_nic /etc/sysconfig/network-scripts/bak-ifcfg-$local_nic-$tag
  ssh $ip cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep NETMASK >> ../conf/ifcfg-br-ex
  ssh $ip cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep PREFIX >> ../conf/ifcfg-br-ex
  ssh $ip cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep DNS1 >> ../conf/ifcfg-br-ex
  ssh $ip cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep GATEWAY >> ../conf/ifcfg-br-ex
  sed -i -e 's#IPADDR=#IPADDR='"$ip"'#g' ../conf/ifcfg-br-ex
  sed -i -e 's#NAME=#NAME='"$local_nic"'#g' ../conf/ifcfg-local_nic
  sed -i -e 's#DEVICE=#DEVICE='"$local_nic"'#g' ../conf/ifcfg-local_nic
  scp ../conf/ifcfg-local_nic root@$ip:/etc/sysconfig/network-scripts/ifcfg-$local_nic
  scp ../conf/ifcfg-br-ex root@$ip:/etc/sysconfig/network-scripts/ifcfg-br-ex
  ssh root@$ip /bin/bash << EOF
  ovs-vsctl add-br br-ex
  ovs-vsctl add-port br-ex $local_nic
  systemctl restart network.service
EOF
done;
### [任一网络节点]测试
.  restart-pcs-cluster-networkers.sh
. /root/keystonerc_admin
./pssh-exe N "ovs-vsctl show"
neutron agent-list
