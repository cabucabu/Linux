#!/bin/bash
. /home/$(whoami)/.bash_profile
cd /home/huawei/program/scripts/2G/HUAWEI_CSV_GETSRC/CM/1440

############ SOURCE ############
SCRIPT_TYPE="U2000RANTLS1H"
CONFIG="/home/huawei/program/scripts/2G/HUAWEI_XML_GETSRC/JAR/HWI_FTP_CONFIG.ip"
keyword="CME_ConfigurationReport_Task"
mode=${1}
period=${2}
dateYMD=${3}
table=${4} 
DETAIL=`cat ${CONFIG} | grep ${SCRIPT_TYPE} | grep ${keyword}`
IP=$(echo ${DETAIL} | cut -d'|' -f7)
USER=$(echo ${DETAIL} | cut -d'|' -f8)
PASSWORD=$(echo ${DETAIL} | cut -d'|' -f9)
PATH_SOURCE=$(echo ${DETAIL} | cut -d'|' -f10)
SOURCE_FILE=""
############ PATH ############
PATH_SCRIPT="/home/huawei/program/scripts/2G/HUAWEI_CSV_GETSRC/CM/1440"
PATH_TEMP="/data/huawei/temp/2G/HUAWEI_CSV_GETSRC/${SCRIPT_TYPE}/SOURCE/$(date +"%Y%m%d")"
PATH_TARGET="/home/huawei/temp/2G/PRS_TEST/CM/${SCRIPT_TYPE}/$(date +"%Y%m%d")"
PATH_LOG="/data/huawei/temp/2G/HUAWEI_CSV_GETSRC/${SCRIPT_TYPE}/log/$(date +"%Y%m%d")"
PATH_LOG_FILE="${PATH_LOG}/$(date +"%Y%m%d%H%M%S").log"

logECHO(){  
	#Write Log file
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $@" 
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $@" >> ${PATH_LOG_FILE}
}

CHECK_PATH () { 
	path=${1}
	pathMakeDir=${2}
	if [ ! -d ${pathMakeDir} ]; then
		mkdir -p ${pathMakeDir}
		chmod 775 ${pathMakeDir}
	fi
}

STOP_ERROR (){
	logECHO " ====== Script is top running.... ======"
	exit 0
}

CHECK_FILE_FROM_SERVER(){
	ip=${1}
	user=${2}
	pass=${3}
	dateYMD=${4}
	logECHO "--------------------------------------------------------"
	logECHO " CHECK_FILE_FROM_SERVER"
	logECHO " ----> get file from find \"${dateYMD}\""
	countFile=`lftp << EOF
			open sftp://${ip}
			user ${user} ${pass}
			ls -l ${PATH_SOURCE} | grep ${dateYMD} | wc -l
			bye
			EOF`
	tmpName=`lftp << EOF
			open sftp://${ip}
			user ${user} ${pass}
			ls ${PATH_SOURCE} | grep ${dateYMD}
			bye
			EOF`
	SOURCE_FILE=${PATH_SOURCE}"/"$(echo ${tmpName} | cut -d' ' -f9)
	if [ ${countFile} == "0" ]; then
		echo "File" ${PATH_SOURCE}"/"$(basename ${PATH_SOURCE})"_["${dateYMD}"]xxxxx.zip not found ... !!"
		logECHO " [ERROR] ----> ${PATH_SOURCE}/$(basename ${PATH_SOURCE})_${dateYMD}00.zip not found ... !!"
		STOP_ERROR
	fi
	logECHO " ----> have file \"$(basename ${SOURCE_FILE})\""
}

GET_FILE_FROM_SERVER(){
	cd ${SCRIPT_TYPE}.tmp 
	ip=${1}
	user=${2}
	pass=${3}
	file=${4}
	logECHO " GET_FILE_FROM_SERVER : $(basename ${file})"
	`lftp << EOF
	open sftp://${ip}
	user ${user} ${pass}
	mget ${file}
	bye
	EOF`
	FILE_IN_TMP=${PATH_SCRIPT}"/"${SCRIPT_TYPE}.tmp"/"$(basename ${SOURCE_FILE})
	unzip -o ${FILE_IN_TMP} > /dev/null 2>&1
	logECHO " UNZIP_FILE : $(basename ${FILE_IN_TMP})"
	for file_CHANG_TO_UNIX in `ls | grep .csv` ; do
		logECHO " ----> $(basename ${file_CHANG_TO_UNIX})"
	done
	cd ..
}

CHANG_TO_UNIX () {
	path_CHANG_TO_UNIX=${1}
	cd ${path_CHANG_TO_UNIX}
	for file_CHANG_TO_UNIX in `ls | grep .csv` ; do
		dos2unix ${file_CHANG_TO_UNIX} > /dev/null 2>&1
	done
	cd ..
}

REPLACE_NULL () {
	path_REPLACE_NULL=${1}
	logECHO " REPLACE_NULL"
	cd ${path_CHANG_TO_UNIX}
	for file_REPLACE_NULL in `ls | grep .csv` ; do
		cp ${file_REPLACE_NULL} ${file_REPLACE_NULL}.tmp
		cat ${file_REPLACE_NULL}.tmp | sed 's/\/0\,/\,/g' > ${file_REPLACE_NULL}
		rm ${file_REPLACE_NULL}.tmp
	done
	cd ..
}

SET_LOG_READY () {
	[ $mode == 'a' ] || [ $mode == 'A' ] && mode="Auto" || mode="Manual"
	logECHO "--------------------------------------------------------"
	logECHO " Start ${mode} Get Source                               "
	logECHO "--------------------------------------------------------"
	logECHO " Start: $(date "+%Y-%m-%d %H:%M:%S")"
	logECHO " PERIOD: ${period}"
	logECHO " IP ADDRESS: ${IP}"
	logECHO " SOURCE PATH: ${PATH_SOURCE}"
	logECHO " TARGET TEMP: ${PATH_TEMP}"
	logECHO " LOG PATH: ${PATH_LOG}"
	logECHO " TARGET PATH: ${PATH_TARGET}"
	logECHO " "
}

SENDFILE_TO_TARGET () {
	path_SENDFILE_TO_TARGET=${1}
	cd ${path_SENDFILE_TO_TARGET}
	
	logECHO " SENDFILE_TO_TARGET"
	for file_SENDFILE_TO_TARGET in `ls | grep .csv` ; do
		mv ${file_SENDFILE_TO_TARGET} $(echo ${file_SENDFILE_TO_TARGET} | sed 's/.csv//g')"-${dateYMD}.csv"
	done
	cd ..
	cp ${path_SENDFILE_TO_TARGET}/*.csv ${PATH_TARGET}
}

END_SCRIPT () {
	logECHO " "
	logECHO " Stop: $(date "+%Y-%m-%d %H:%M:%S")"
	logECHO "--------------------------------------------------------"
	logECHO "... ${mode} GetSource Complete ...                      "
	logECHO "--------------------------------------------------------"
	logECHO " "
}

MOVE_TMP () {
	logECHO " MOVE_TMP TO : ${PATH_TEMP}"
	path_MOVE_TMP=${1}
	cp ${path_MOVE_TMP}/*.csv ${PATH_TEMP}/
	rm -r ${path_MOVE_TMP}
	dir_del="/data/huawei/temp/2G/HUAWEI_CSV_GETSRC/U2000RANPRS1H/SOURCE/$(date --date='-7 day' '+%Y%m%d')"
	#delete after 7 day
	if [ -d "$dir_del" ]; then
		rm -r ${dir_del}
	fi
}
	
###################################################################
###### #################################################### #######
#                           Main Program                          #
#						 Create by Chatchai						  #
###### #################################################### #######
###################################################################

CHECK_PATH "LOG PATH" ${PATH_LOG}
CHECK_PATH "PATH_TEMP" ${PATH_TEMP}
CHECK_PATH "TARGET PATH" ${PATH_TARGET}
CHECK_PATH "SCRIPT_TYPE" "${SCRIPT_TYPE}.tmp"
SET_LOG_READY
CHECK_FILE_FROM_SERVER ${IP} ${USER} ${PASSWORD} ${dateYMD}
GET_FILE_FROM_SERVER ${IP} ${USER} ${PASSWORD} ${SOURCE_FILE} 
CHANG_TO_UNIX "${SCRIPT_TYPE}.tmp"
REPLACE_NULL "${SCRIPT_TYPE}.tmp"
SENDFILE_TO_TARGET "${PATH_SCRIPT}/${SCRIPT_TYPE}.tmp"
MOVE_TMP "${PATH_SCRIPT}/${SCRIPT_TYPE}.tmp"
END_SCRIPT
exit 0
