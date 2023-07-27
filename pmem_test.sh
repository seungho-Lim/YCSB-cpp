#!/bin/bash

kvstore="pmemdb"; ycsb="ycsbpmem"
thrcount=12
opcount=$((2000)) #200M
sleeptime=1 # time interval between runs. 

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

reset_filesystem_for_pmem () {
  sudo umount /mnt/pmem0 2> /dev/null
  sudo umount /dev/pmem0 2> /dev/null

  sudo /sbin/mkfs.ext4 /dev/pmem0 -F
  sudo mount -o dax /dev/pmem0 /mnt/pmem0/
  sudo sh -c "/usr/bin/echo 3 > /proc/sys/vm/drop_caches"
}

do_ycsb_all () { 
mkdir -p $RES_DIR
   
 echo -en "" > ${RES_DIR}/size.dat
  
# sudo umount /mnt/${kvstore}_test 2> /dev/null
 sudo umount /mnt/pmem0 2> /dev/null

# sudo rm -rf /mnt/${kvstore}_test
 sudo rm -rf /mnt/pmem0
# sudo mkdir /mnt/${kvstore}_test
 sudo mkdir /mnt/pmem0/
# sudo chmod 777 /mnt/pmemdb_test
 sudo chmod 777 /mnt/pmem0
 printf "threadcount : %s\n" ${thrcount}
 reset_filesystem_for_pmem
# reset_filesystem
# sudo rm -rf /mnt/${kvstore}_test/* 
 sudo rm -rf /mnt/pmem0/*
# sudo mkdir /mnt/pmemdb_test/nvme_arena
 sudo mkdir /mnt/pmem0/pmem_arena
 sudo mkdir /mnt/pmem0/kvs
 sudo mkdir /mnt/pmem0/db
 sudo mkdir /mnt/pmem0/wal
# sudo chmod 777 /mnt/pmemdb_test/nvme_arena
 sudo chmod 777 /mnt/pmem0/pmem_arena
 sudo chmod 777 /mnt/pmem0/kvs
 sudo chmod 777 /mnt/pmem0/db
 sudo chmod 777 /mnt/pmem0/wal

#  dstat -T -d -m --output "${RES_DIR}/${kvstore}.csv" &

  do_ycsb run putonly 



# mv ${RES_DIR}/LOG_load_putonly ${RES_DIR}/LOG_load_putonly_first

#Since workload e is slower than other core workloads, set 1/10 amount.
  do_ycsb run e 2000



#  do_ycsb run b
#  do_ycsb run c
#  do_ycsb run f
#  do_ycsb run d
    
#  reset_filesystem

#  do_ycsb load putonly 

#  do_ycsb run e $((200*1000*1000))

#  sudo cp /mnt/${kvstore}_test/LOG* ${RES_DIR}/
#  sudo cp ~/sh/YCSB-cpp/db_test.sh ${RES_DIR}/
  
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

