#!/bin/sh
#
# Dropbox Backup Cron Job Script v0.1
#
# Copyright (C) 2012 http://shuyz.com 
# 
# This script is expected to run on OpenShift, you may port it to other VPS by doing a little coding.
#

# 1: debug  0: run
debug=1

# database information
db_host=127.0.0.1
db_port=3306
db_user=${1}
db_pass=${2}
db_name=${3}
src_folder=${4}
# the location of dropbox_uploader bash script
dropbox_uploader=${5}

cur_dir=`pwd`
src_file=`basename ${src_folder}`
remote_folder=/${src_file}

# You may just keep the configuration below
bak_time=$(date +%Y%m%d%H%M%S)
tmp_folder=/tmp/${src_file}_${bak_time}
bak_file=${tmp_folder}/${src_file}.tar.bz2
db_file=${tmp_folder}/${src_file}.sql
log_file=/tmp/${src_file}_${bak_time}.log

# save message to log file or echo message on the screen
function showmsg() {
	if [ ${debug} -eq 1 ]; then 
		echo [$(date +"%Y-%m-%d %H:%M:%S")] "$1"
	else
		if [ -f ${log_file} ]; then
			echo [$(date +"%Y-%m-%d %H:%M:%S")] "$1" >> ${log_file}
		else

			echo [$(date +"%Y-%m-%d %H:%M:%S")] "$1" > ${log_file}
		fi
	fi
}

# remove temporary files and exit with error code
function endnow() {
	showmsg "remove temporary files and directories"
	if [ -d ${tmp_folder} ]; then
		rm -rf ${tmp_folder}
	fi

	if [ -f ${bak_file} ]; then
		rm ${bak_file}
	fi

	if [ -f ${tmp_folder}.tar.bz2 ]; then
		rm ${tmp_folder}.tar.bz2
	fi
	
	# exit
	if [ "$1" -eq 0 ]; then
		showmsg "backup succeed!"
		exit 0
	else
		showmsg "backup failed!"
		exit 1
	fi
}

# check the exit code of previous command
function checkresult() {
	if [ $? -ne 0 ]; then
		showmsg "$1"
		endnow 1
	fi
}

showmsg "creating backup directory on ${tmp_folder}"
mkdir -p ${tmp_folder}
checkresult "failed to create backup directory"

showmsg "exporting databases ${db_name} to ${db_file}"
mysqldump -h${db_host} -P${db_port} -u${db_user} -p${db_pass} ${db_name} > ${db_file}
checkresult "failed to export database"

showmsg "archiving ${src_folder} ${bak_file}"
cd ${src_folder}
checkresult "cannot change working directory to ${src_folder}"
tar -jcf ${bak_file} `ls -A` >> ${log_file}
checkresult "failed to archive files"

showmsg "archiving ${tmp_folder} ${tmp_folder}.tar.bz2"
cd ${tmp_folder}
checkresult "cannot change working directory to ${tmp_folder}"
tar -jcf ${tmp_folder}.tar.bz2 `ls -A` >> ${log_file}
checkresult "failed to pack all files"

showmsg "uploading ${tmp_folder}.tar.bz2 to dropbox ${remote_folder}"
cd ${cur_dir}
checkresult "cannot change working directory to ${cur_dir}"
sh $dropbox_uploader upload ${tmp_folder}.tar.bz2 /${remote_folder}/ >> ${log_file}
checkresult "upload failed!"

endnow 0
