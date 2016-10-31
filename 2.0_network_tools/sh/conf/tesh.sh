local_ip=$(ip addr show dev $local_nic scope global | grep "inet " | sed -e "s#.*inet ##g" -e "s#/.*##g"|head -n 1)
echo $local_ip
sed -i -e 's#\#ServerName www.example.com:80#ServerName '"$(hostname)"'#g'  /etc/httpd/conf/httpd.conf
sed -i -e 's#0.0.0.0#'"$local_ip"'#g'  wsgi-keystone.conf:wq

