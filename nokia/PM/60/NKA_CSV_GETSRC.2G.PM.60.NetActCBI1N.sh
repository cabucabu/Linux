#!/bin/bash

#### FUNCTION ####
CHECK_PATH ()
{ 
	path=${1}
	pathMakeDir=${2}
	if [ ! -d ${pathMakeDir} ]; then
		mkdir -p ${pathMakeDir}
		chmod 775 ${pathMakeDir}
	fi
}

logECHO ()
{
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $@" 
	#echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $@" >> ${FILE_LOG}
}

START_LOG_READY ()
{
	[ $mode == 'a' ] || [ $mode == 'A' ] && mode="Auto" || mode="Manual"
	logECHO "--------------------------------------------------------"
	logECHO " Start ${mode} Get Source                               "
	logECHO "--------------------------------------------------------"
	logECHO " Start: $(date "+%Y-%m-%d %H:%M:%S")"
	logECHO " KEYWORD: ${find_key}"
	logECHO " IP ADDRESS: ${ftp_ip}"
	logECHO " SOURCE PATH: ${PATH_TMP}"
	logECHO " TARGET PATH: ${PATH_TARGET}"
	logECHO " TMP PATH: ${PATH_TMP}"
	logECHO " LOG PATH: ${PATH_LOG}"
}

INITAIL_SET ()
{ 
    detail=$(cat ${CFG} | grep "NetActCBI1N") 
    ftp_ip=$(echo ${detail} | cut -d'|' -f7)
    ftp_user=$(echo ${detail} | cut -d'|' -f8)
    ftp_pass=$(echo ${detail} | cut -d'|' -f9)
    ftp_path=$(echo ${detail} | cut -d'|' -f10)
}

CHECK_FILE_IN_SERVER () 
{
    logECHO "--------------------------------------------------------"
	logECHO " CHECK_FILE_FROM_SERVER"
	logECHO " ----> get file from find \"${find_key}\""
	countFile=`lftp << EOF 
		open sftp://${ftp_ip} 
		user ${ftp_user} ${ftp_pass} 
		ls -l ${ftp_path} | grep ${find_key} | wc -l 
		bye 
		EOF` 
	nameFile=`lftp << EOF 
		open sftp://${ftp_ip} 
		user ${ftp_user} ${ftp_pass} 
		ls ${ftp_path} | grep ${find_key} 
		bye 
		EOF` 
	if [ ${countFile} == "0" ]
	then
		logECHO " [ERROR] : find by key \"${find_key}\" not found ... !!"
		logECHO "--------------------------------------------------------"
		END_SCRIPT
		exit 0
	fi
    echo "countFile : ${countFile}"
    echo "nameFile : ${nameFile}"
    echo "nameFile : "$(echo ${nameFile##* })
}

END_SCRIPT () 
{	
	logECHO " Stop: $(date "+%Y-%m-%d %H:%M:%S")"
	logECHO "--------------------------------------------------------"
	logECHO "... ${mode} GetSource Complete ...                      "
	logECHO "--------------------------------------------------------"
	logECHO " "
}

##### PATH AND PARAM #####
mode=${1}
dateYMDH=${2}
dateYMD=$(echo ${dateYMDH:0:8})
dateYDM=$(echo ${dateYMDH:0:4})""$(echo ${dateYMDH:6:2})""$(echo ${dateYMDH:4:2})
H=$(echo ${dateYMDH:8:2})
find_key="PMS_GSM_${dateYDM}_${H}"
PATH_PROGRAM="/home/nokia/program/scripts/2G/NKA_CSV_GETSRC/PM/60"
PATH_LOG="/data/nokia/temp/2G/HUAWEI_CSV_GETSRC/PM/60/NetActCBI1N/log/${dateYMD}"
PATH_TMP="/data/nokia/temp/2G/HUAWEI_CSV_GETSRC/PM/60/NetActCBI1N/tmp/${dateYMD}"
PATH_TARGET="/data/nokia/temp/2G/HUAWEI_CSV_GETSRC/PM/60/NetActCBI1N/${dateYMD}"
FILE_LOG="${PATH_LOG}/$(date +"%Y%m%d%H%M%S").log"
CFG="/home/nokia/program/scripts/2G/NKA_CSV_GETSRC/CFG/NKA_FTP_CONFIG.ip"

##### MAIN PROCESS ####
CHECK_PATH ${PATH_PROGRAM}
CHECK_PATH ${PATH_LOG}
CHECK_PATH ${PATH_TMP}
CHECK_PATH ${PATH_TARGET}
INITAIL_SET
START_LOG_READY
CHECK_FILE_IN_SERVER
