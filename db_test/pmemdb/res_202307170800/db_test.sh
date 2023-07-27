#!/bin/bash

kvstore="rocksdb"; ycsb="ycsbrocks"
#kvstore="remixdb"; ycsb="ycsbremix"
#kvstore="pebblesdb"; ycsb="ycsbpebbles"
#kvstore="lcfdb"; ycsb="ycsblcf"
thrcount=12
opcount=$((200000000)) #200M
#opcount=20000000
sleeptime=60 # time interval between runs. 

RES_DIR="/home/smrc/sh/db_test/${kvstore}/res_`date "+%Y%m%d%H%M"`"

array=(a b c d e f)

main () {
  do_ycsb_all 
}

reset_filesystem () {
  sudo umount /mnt/${kvstore}_test 2> /dev/null
  sudo umount /dev/nvme1n1 2> /dev/null

  sudo /sbin/mkfs.ext4 /dev/nvme1n1 -F
  sudo mount /dev/nvme1n1 /mnt/${kvstore}_test
  sudo sh -c "/usr/bin/echo 3 > /proc/sys/vm/drop_caches"
}

do_ycsb_all () { 
mkdir -p $RES_DIR
   
 echo -en "" > ${RES_DIR}/size.dat
  
 sudo umount /mnt/${kvstore}_test 2> /dev/null

 sudo rm -rf /mnt/${kvstore}_test
 sudo mkdir /mnt/${kvstore}_test
 printf "threadcount : %s\n" ${thrcount}
 reset_filesystem 
 sudo mount /mnt/${kvstore}_test
 sudo rm -rf /mnt/${kvstore}_test/* 

#  dstat -T -d -m --output "${RES_DIR}/${kvstore}.csv" &

  do_ycsb run putonly 



# mv ${RES_DIR}/LOG_load_putonly ${RES_DIR}/LOG_load_putonly_first

#Since workload e is slower than other core workloads, set 1/10 amount.
  do_ycsb run e 20000000




#  do_ycsb run b
#  do_ycsb run c
#  do_ycsb run f
#  do_ycsb run d
    
#  reset_filesystem

#  do_ycsb load putonly 

#  do_ycsb run e $((200*1000*1000))

  sudo cp /mnt/${kvstore}_test/LOG* ${RES_DIR}/
  sudo cp ~/sh/YCSB-cpp/db_test.sh ${RES_DIR}/
  
#  mv ~/YCSB/YCSB-cpp/*_time.txt ${RES_DIR}/
#  kill $(ps -ef | grep dstat | awk '{print $2}')
#  sudo umount /dev/nvme1n1 2> /dev/null
}

do_ycsb () {
  type="$1"; workload="$2"

  if [ -z $3 ]; then 
    testcount=${opcount}
  else
    testcount=$3
  fi

  sudo cp ~/sh/YCSB-cpp/workloads/workload${workload} ${RES_DIR}/
  printf "Start: %s %s %s %s\n" ${type} ${workload} ${opcount} ${testcount} 

  sudo ./${ycsb} -${type} -db ${kvstore} -P workloads/workload${workload} -P ${kvstore}/${kvstore}.properties \
    -p threadcount=${thrcount} -p recordcount=${opcount} -p operationcount=${testcount} -s \
    >> ${RES_DIR}/${kvstore}_${type}_${workload}.dat

  echo -en "${type}_${workload}  " >> ${RES_DIR}/size.dat
  sudo df -Th /dev/nvme1n1 >> ${RES_DIR}/size.dat
#  sudo cp /mnt/${kvstore}_test/LOG ${RES_DIR}/LOG_${type}_${workload}

  printf "Done : %s %s %s %s\n" ${type} ${workload} ${opcount} ${testcount} 

  sleep ${sleeptime}
  sudo sh -c " echo 3 > /proc/sys/vm/drop_caches"

}

main

