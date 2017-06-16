#!/bin/sh
./pssh-exe A "usermod -s /bin/bash nova"
su - nova -c "ssh-keygen -t rsa"
cat << EOF > /var/lib/nova/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
cat /var/lib/nova/.ssh/id_rsa.pub > /var/lib/nova/.ssh/authorized_keys
chmod 600 /var/lib/nova/.ssh/authorized_keys
./scp-exe H /var/lib/nova/.ssh/ /var/lib/nova/
./pssh-exe H "chown nova:nova -R /var/lib/nova/.ssh/"
### Check SSH
su - nova -c "ssh nova@compute02 cd ~ && pwd"
