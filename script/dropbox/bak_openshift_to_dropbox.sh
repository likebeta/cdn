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

# Change the configuration below according to your apps
#
# OpenShift application name
appname=app-root
# add folders to backup. seperate with space if more than one
src_folder=~/${appname}/repo/php
# database information
db_host=127.0.0.1
db_port=3306
db_user=admin
db_pass=M5NM3
db_name=wordpress
# the location of dropbox_uploader bash script
dropbox_uploader=~/${appname}/repo/dropbox/dropbox_uploader.sh
# remote location in dropbox, DO NOT END WITH SLASH!
remote_loc=/backup/openshift
# That's all, all necessary configuration is done!


# You may just keep the configuration below
bak_time=$(date +%Y%m%d%H%M%S)
tmp_folder=~/php/tmp/bak_${bak_time}/
file_name=bak_${bak_time}.zip
bak_file=~/php/tmp/${file_name}
db_file=${tmp_folder}${db_name}.sql
log_file=~/php/logs/dropbox_bak_${bak_time}

# save message to log file or echo message on the screen
function showmsg() {
	if [ ${debug} -eq 1 ]; then 
		echo [$(date +%Y/%m/%d.%H:%M:%S)] "$1"
	else
		if [ -f ${log_file} ]; then
			echo [$(date +%Y/%m/%d.%H:%M:%S)] "$1" >> ${log_file}
		else

			echo [$(date +%Y/%m/%d.%H:%M:%S)] "$1" > ${log_file}
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
mkdir ${tmp_folder}
checkresult "failed to create backup directory"

showmsg "exporting databases: ${db_name}"
mysqldump -h${db_host} -p${db_port} -u${db_user} -p${db_pass} ${db_name} > ${db_file}
checkresult "failed to export database"

showmsg "archiving files in folder ${src_folder}"
cd ${src_folder}
checkresult "cannot change working directory to ${src_folder}"
zip -rvy ${tmp_folder}files.zip * >> ${log_file}
checkresult "failed to archive files"

showmsg "pack all files and database as ${bak_file}"
cd ${tmp_folder}
checkresult "cannot change working directory to ${tmp_folder}"
zip -rvy ${bak_file} * >> ${log_file}
checkresult "failed to pack all files"

showmsg "uploading ${bak_file} to dropbox"
$dropbox_uploader upload ${bak_file} ${remote_loc}/${file_name} >> ${log_file}
checkresult "upload failed!"

endnow 0
