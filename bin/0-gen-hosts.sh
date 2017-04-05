#!/bin/sh
. ../0-set-config.sh

> hosts/nodes.txt
> hosts/controllers.txt
> hosts/networkers.txt
> hosts/hypervisors.txt

for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  echo "$ip" >> hosts/nodes.txt
  echo "$ip" >> hosts/controllers.txt
done;

for ((i=0; i<${#networker_map[@]}; i+=1));
do
  name=${networker_name[$i]};
  ip=${networker_map[$name]};
  echo "$ip" >> hosts/nodes.txt
  echo "$ip" >> hosts/networkers.txt
done;

for ((i=0; i<${#hypervisor_map[@]}; i+=1));
do
  name=${hypervisor_name[$i]};
  ip=${hypervisor_map[$name]};
  echo "$ip" >> hosts/nodes.txt
  echo "$ip" >> hosts/hypervisors.txt
done;

for ((i=0; i<${#hypervisor_map[@]}; i+=1));
do
  name=${hypervisor_name[$i]};
  ip=${hypervisor_map[$name]};
  echo "$ip" >> hosts/nodes.txt
  echo "$ip" >> hosts/hypervisors.txt
done;
