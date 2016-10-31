
controller_name=(${!controller_map[@]});

finish_flag=0
while_flag=0
service="mongod"

while [ $while_flag -lt 10 ]
do
  echo "#########Check all $service are running! ##########"
  finish_flag=0
  for ((i=0; i<${#controller_map[@]}; i+=1));
    do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        status=$(ssh root@$ip systemctl status $service|grep Active:|awk '{print $3}'|grep "running")
        echo $status
        if [ $status != "" ];then
          echo "running"
        else
          echo "dead"
          let finish_flag++
        fi
    done;
  if [ $finish_flag -eq 0 ];then
    echo "All $service are running!"
    while_flag=10
  else
    echo "Please check the $service in pacemaker resource!"
    sleep 5
  fi
  let while_flag++
echo $while_flag
done

if [  $finish_flag -ne 0 ]; then
    echo "Not all $service are running!"
    exit 2
fi

