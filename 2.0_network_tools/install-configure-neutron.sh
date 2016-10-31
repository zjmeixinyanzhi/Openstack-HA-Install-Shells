#!/bin/sh
controller_name=(${!controller_map[@]});
networker_name=(${!networker_map[@]});

sh_name=neutron_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
sh_name_1=neutron_ovs_configure.sh
source_sh_1=$(echo `pwd`)/sh/$sh_name_1
target_sh=/root/tools/t_sh/
  
##### 
for ((i=0; i<${#networker_map[@]}; i+=1));
  do
        name=${networker_name[$i]};
        ip=${networker_map[$name]};
        echo "-------------$name------------"
	ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name $virtual_ip $virtual_network_ip $local_nic $data_nic $password
  done;
##### set nova configure in controller nodes
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
	ssh root@$ip mkdir -p $target_sh
  done;

### [任一节点]添加pacemaker资源
pcs resource create neutron-server systemd:neutron-server op start timeout=90 --clone interleave=true

pcs resource create neutron-scale ocf:neutron:NeutronScale --clone globally-unique=true clone-max=3 interleave=true
pcs constraint order start neutron-server-clone then neutron-scale-clone

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

### ovs 操作
echo "ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex "$local_nic
for ((i=0; i<${#networker_map[@]}; i+=1));
  do
        name=${networker_name[$i]};
        ip=${networker_map[$name]};
        echo "-------------$name------------"
	ssh root@$ip mkdir -p $target_sh
        scp $source_sh_1 root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name_1 $local_nic
  done;
### [任一节点]测试
echo "Pcs cluster is restarting! If is stuck, please type Ctrl+C to terminate and it'll continue!"
. restart-pcs-cluster.sh
. /root/keystonerc_admin
ovs-vsctl show
neutron agent-list
