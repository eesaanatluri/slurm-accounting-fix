#!/bin/bash

while read -r line
do

	uid=`echo $line | cut -d ',' -f1`
	slurm_acct_name=`echo $line | cut -d ',' -f2`

	total_jobs=`mysql -N -u root -D slurmdb -e "select count(1) from ohpc_job_table where id_user=$uid and account IS NULL;"`

	#printf "User $slurm_acct_name with user ID $uid has $total_jobs jobs with account name null \n"

	#printf "Updating $total_jobs records for user $slurm_acct_name with user ID $uid \n"

	printf "UPDATE ohpc_job_table SET account=\'$slurm_acct_name\' WHERE id_user=$uid and account IS NULL;\n"

	#mysql -u root -D slurmdb -e \"UPDATE ohpc_job_table SET account=$slurm_acct_name WHERE id_user=$uid and account IS NULL;\"
done<"$1"
