 #!/bin/sh
systemctl disable firewalld.service
systemctl stop firewalld.service
sed -i -e "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
sed -i -e "s#SELINUXTYPE=targeted#\#SELINUXTYPE=targeted#g" /etc/selinux/config

sestatus=$(sestatus -v |grep "SELinux status:"|awk '{print $3}')
echo $sestatus
if [ $sestatus = "enabled" ];then
  echo "Reboot now? (yes/no)"
  read flag
  if [ $flag = "yes" ];then
    echo "Reboot now!"
    reboot
  else
    echo "You should reboot manually!"
  fi
else
  echo "SELinux is disabled!"
fi
