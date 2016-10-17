echo "mysql -uroot -p$password_galera_root -h $virtual_ip -e \"CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'controller01' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;\"">tmp.sh
