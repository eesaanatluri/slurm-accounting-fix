#!/bin/bash

while read -r line
do
	uid=`echo $line | cut -d ',' -f1`
	slurm_user_name=`echo $line | cut -d ',' -f2`
	data1=$(mysql -u root -D slurmdb<<<"SELECT distinct(id_assoc) , acct, user  FROM ohpc_assoc_table  where user='$slurm_user_name';")
	id_assoc=`echo $data1 | cut -d ' ' -f4`
	acct=`echo $data1 | cut -d ' ' -f5`
	user=`echo $data1 | cut -d ' ' -f6`
	data1=$(mysql -u root -D slurmdb<<<"UPDATE ohpc_job_table  set id_assoc='$id_assoc' where id_user='$uid' and id_assoc=0;\
UPDATE ohpc_job_table  set account='$acct' where id_user='$uid' and account='';") 
done<"$1"
