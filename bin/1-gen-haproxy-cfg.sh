#!/bin/sh
. ../0-set-config.sh
target_cfg=../conf/haproxy.cfg
rm -rf $target_cfg
\cp /etc/haproxy/haproxy.cfg $target_cfg
\cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
if [ $1 = "base" ];then
  cat ../conf/haproxy/base > $target_cfg 
else
  cat ../conf/haproxy/$1 >> $target_cfg 
fi
sed -i -e 's#bind XX.XX.XX.XX#bind '"$virtual_ip"'#g' $target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  sed -i -e 's#'"$name"' XX.XX.XX.XX#'"$name"' '"$ip"'#g' $target_cfg
done;
## 拷贝文件到其他节点
./scp-exe C $target_cfg /etc/haproxy/haproxy.cfg
