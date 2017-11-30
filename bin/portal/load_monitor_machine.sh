. 0-set-config.sh
python physical_machine_loader.py
mysql -uroot -p$password_galera_root -h $virtual_ip -e "use cloud;select * from physical_machine;
select * from physical_machine_physical_machine_type;
select * from machine_service_monitor_record;
select * from alarm_setting;"
 
