#!/bin/sh
cd bin
### SSH
./set-ssh-nodes.sh
### 
./set-network-config.sh
./set-hostname.sh
./set-chrony.sh
./disable_firewall_selinux.sh
./set-local-yum-repos.sh
