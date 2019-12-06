#!/bin/bash

total_jobs=`mysql -N -u root -D slurmdb -e "select count(1) from ohpc_job_table where account IS NULL or id_assoc=0;"`
echo "Total number of jobs to be updated = $total_jobs"
if [ $total_jobs = "0" ]; then
	exit 1
fi
total_jobs_updated=0

while read -r line
do

	progress=$(( total_jobs_updated*100/total_jobs ))
	echo -en "\rPROGRESS: $progress %"
	if [ $progress = "100" ]; then
					break;
	fi

	uid=`echo $line | cut -d ',' -f1`
	slurm_user_name=`echo $line | cut -d ',' -f2`
	##Getting the missing assoc id from ohpc_assoc_table
	slurm_assocs=`mysql -N -u root -D slurmdb -e "SELECT distinct(id_assoc), acct  FROM ohpc_assoc_table  where user='$slurm_user_name';"`
	id_assoc=`echo $slurm_assocs | cut -d ' ' -f1`
	acct=`echo $slurm_assocs | cut -d ' ' -f2`
	#echo "updating user with id_assoc with account name and UID = "$id_assoc, $acct "and "$uid

	##Updating the missing data in the table in two statements because in some of the cases id_assoc is missing but account name is present.
	row_count_id_0=`mysql -N -u root -D slurmdb -e "UPDATE ohpc_job_table  set id_assoc='$id_assoc' where id_user='$uid' and id_assoc=0;\
		SELECT ROW_COUNT();"`
	row_count_accnt=`mysql -N -u root -D slurmdb -e "UPDATE ohpc_job_table  set account='$acct' where id_user='$uid' and account='' or account IS NULL;\
		SELECT ROW_COUNT();"`

	total_jobs_updated=$(( total_jobs_updated+row_count_accnt+row_count_id_0 ))

done<"$1"
printf "\n Total jobs updated = $total_jobs_updated\n"
