## Steps to fix slurmdb for jobs not having account names.

### Introduction
The goal here is to fix the NULL entries in the account column for the jobs that ran when the slurm accounts were not set. This causes an issue in XDMoD, when we try to view the job metrics, they would be categorized into an unknown category. 

If you would like to follow along, get yourself a test environment by following the instructions from the Setup section of the [README.md]([https://github.com/eesaanatluri/slurm-accounting-fix/blob/master/README.md](https://github.com/eesaanatluri/slurm-accounting-fix/blob/master/README.md))
 
Total no. of jobs having account column null. These jobs need to be fixed.
> MariaDB [slurmdb]> select count(1) from ohpc_job_table where time_start>1441083600 and account IS NULL;
+----------+
| count(1) |
+----------+
|   341386 |
+----------+
Note: 1441083600 is epoch timestamp for 2015-09-01 (When we started using Slurm at UAB.) 

Get unique uids of jobs that ran without a slurm account defined.
```
mysql -N slurmdb -u root -e "select distinct(id_user) from ohpc_job_table where time_start>1441083600 and account IS NULL order by id_user;" > fix-uids.txt
 ```

Move the file having a list of uids to Cheaha to get their usernames.
> The following two steps should run on Mac
```
rsync centos@164.111.161.164:~/fix-uids.txt ~/projects/data
```
```
rsync ~/projects/data/fix-uids.txt atlurie@cheaha.rc.uab.edu:~
```

Get usernames for the uid list in the above step from production (Cheaha).
```
while read -r line; do echo $line,`id -n -u $line`; done < fix-uids.txt > fix-uids-name.csv
```
> The following two steps should run on Mac
```
rsync atlurie@cheaha.rc.uab.edu:~/fix-uids-name.csv ~/projects/data
```
```
rsync fix-uids-name.csv centos@164.111.161.164:~
```

### Usage

Prepare sql script containing update statements.
```
./slurmdb-fix-job-null-accounts.sh fix-uids-name.csv > slurmdb-fix-job-null-accounts.sql
```
Apply the fix 
```
mysql -u root -D slurmdb < slurmdb-fix-job-null-accounts.sql
```
### Test

You can confirm that the DB is fixed by running the following command
```
sacct --allusers --duplicates --clusters ohpc --format jobid,account,group,gid,user,uid,state,jobname --state CANCELLED,COMPLETED,FAILED --starttime 2015-01-01T08:00:35 --endtime 2016-12-31T11:59:59 | less
```

### XDMOD

Truncate all the tables containing job data and you can then re-shred and re-ingest your resource manager data, for the DB fix we did above to reflect in XDMOD.

```
sudo xdmod-admin --truncate --jobs 
```
```
sudo xdmod-slurm-helper -r ohpc --start-time 2015-09-01T00:00:00 --end-time 2019-10-14T11:59:59
```
```
sudo xdmod-ingestor --start-date 2015-09-01 --end-date 2019-10-15
```
