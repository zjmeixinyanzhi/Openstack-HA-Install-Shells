#!/bin/sh
### 生成物理机列表文件
echo "=== 生成配置文件 ===";
cat /dev/null > physical_machine_list.txt
for type in $(cat physical_machine_list_template |awk -F "|" '{print $1}');
do
  HOST_TYPE=$(cat physical_machine_list_template |grep $type|awk -F "|" '{print $1}')
  HOST_CORES=$(cat physical_machine_list_template |grep $type|awk -F "|" '{print $2}')
  HOST_MEMORY=$(cat physical_machine_list_template |grep $type|awk -F "|" '{print $3}')
  HOST_DISK=$(cat physical_machine_list_template |grep $type|awk -F "|" '{print $4}')
  HOST_SERVICES=$(cat physical_machine_list_template |grep $type|awk -F "|" '{print $5}')
  if [[ "$type" = "CONTROLLER_NODE" ]];then
    for h in ${!controller_map[@]}
    do
      if [[ "$networker_split" = "no" ]];then
        HOST_NETWORK_SERVICES=$(cat physical_machine_list_template |grep "NETWORK_NODE"|awk -F "|" '{print $5}')
        echo $h"|"$HOST_TYPE"|"$HOST_CORES"|"$HOST_MEMORY"|"$HOST_DISK"|" \
        ${controller_map[${h}]}"|CONNECTIVITY,"$HOST_SERVICES","$HOST_NETWORK_SERVICES>> physical_machine_list.txt
      elif [[ "$networker_split" = "yes" ]];then 
        echo $h"|"$HOST_TYPE"|"$HOST_CORES"|"$HOST_MEMORY"|"$HOST_DISK"|" \
        ${controller_map[${h}]}"|CONNECTIVITY,"$HOST_SERVICES>> physical_machine_list.txt
      fi
    done
  fi
  if [[ "$type" = "NETWORK_NODE" && "$networker_split" = "yes" ]];then
    for h in ${!networker_map[@]}
    do
      echo $h"|"$HOST_TYPE"|"$HOST_CORES"|"$HOST_MEMORY"|"$HOST_DISK"|" \
      ${networker_map[${h}]}"|CONNECTIVITY,"$HOST_SERVICES>> physical_machine_list.txt
    done
  fi
  if [[ "$type" = "COMPUTE_NODE" ]];then
    for h in ${!hypervisor_map[@]}
    do
      echo $h"|"$HOST_TYPE"|"$HOST_CORES"|"$HOST_MEMORY"|"$HOST_DISK"|" \
      ${hypervisor_map[${h}]}"|CONNECTIVITY,"$HOST_SERVICES>> physical_machine_list.txt
    done
  fi
done
echo $(cat physical_machine_list.txt)
echo "=== INFO CHECK ===>>> " "请检查物理机信息是否正确，按任意键继续[]"
read answer
### 导入到数据库
sed \
      -e "s/TAG_DATABASE_HOST/$virtual_ip/g" \
      -e "s/TAG_DATABASE_NAME/cloud/g" \
      -e "s/TAG_DATABASE_USERNAME/root/g" \
      -e "s/TAG_DATABASE_PASSWORD/$password_galera_root/g" \
      physical_machine_loader.py > /tmp/physical_machine_loader.py
python /tmp/physical_machine_loader.py
### 查询导入结果
mysql -uroot -p$password_galera_root -h $virtual_ip -e "use cloud;select * from physical_machine;
select * from physical_machine;
select * from physical_machine_physical_machine_type;
select * from monitor_setting;"
