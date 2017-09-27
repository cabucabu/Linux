#!/bin/bash
. /home/$(whoami)/.bash_profile
cd /home/huawei/program/scripts/2G/HUAWEI_CSV_GETSRC/PM/60

############ SOURCE ############
CONFIG="/home/huawei/program/scripts/2G/HUAWEI_XML_GETSRC/JAR/HWI_FTP_CONFIG.ip"
CFG="/home/huawei/program/scripts/2G/HUAWEI_CSV_GETSRC/PM/60/HUAWEI_CSV_GETSRC.PM.2G.60.1.U2000PRSCMI1H.IP1.cfg"
mode=${1}
dateYMDH=${2}
dateYMD=${dateYMDH:0:8}
period=${3}
type=${4}
DETAIL=`cat ${CONFIG} | grep ${type} | grep 'PM|2G|60|1|U2000PRSCMI1H'`
IP=$(echo ${DETAIL} | cut -d'|' -f7)
USER=$(echo ${DETAIL} | cut -d'|' -f8)
PASSWORD=$(echo ${DETAIL} | cut -d'|' -f9)
PATH_SOURCE=$(echo ${DETAIL} | cut -d'|' -f10)
SOURCE_FILE=""

############ PATH ############
PATH_SCRIPT="/home/huawei/program/scripts/2G/HUAWEI_CSV_GETSRC/PM/60"
PATH_TMP="/data/huawei/temp/HUAWEI_CSV_GETSRC/U2000PRSCMI1H/SOURCE/${dateYMD}"
PATH_TARGET="/data/huawei/temp/HUAWEI_CSV_GETSRC/U2000PRSCMI1H/${dateYMD}"
PATH_LOG="/data/huawei/temp/HUAWEI_CSV_GETSRC/U2000PRSCMI1H/log/$(date +"%Y%m%d")"
PATH_LOG_FILE="${PATH_LOG}/$(date +"%Y%m%d%H%M%S").log"


MOVE_FILE_TMP () 
{
	logECHO " MOVE_FILE_TMP"
	mv *.zip ${PATH_TMP}
	mv *.csv ${PATH_TMP}
	
	#delete old source
	dirDel="/data/huawei/temp/HUAWEI_CSV_GETSRC/U2000PRSCMI1H/SOURCE/"$(date --date="-7 day" "+%Y%m%d")
	if [ -d "$dirDel" ]; then
		logECHO " ----> delete directory ${dirDel}"
		rm -r ${dirDel}
	fi
}

CHECK_PATH () 
{ 
	path=${1}
	pathMakeDir=${2}
	if [ ! -d ${pathMakeDir} ]; then
		mkdir -p ${pathMakeDir}
		chmod 775 ${pathMakeDir}
	fi
}

logECHO()
{  
	#Write Log file
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $@" 
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $@" >> ${PATH_LOG_FILE}
}

CHECK_FILE_FROM_SERVER()
{
	ip=${1}
	user=${2}
	pass=${3}
	fileName=${4}
	logECHO "--------------------------------------------------------"
	logECHO " CHECK_FILE_FROM_SERVER"
	logECHO " ----> get file from find \"${fileName}\""
	countFile=`lftp << EOF
			open sftp://${ip}
			user ${user} ${pass}
			ls -l ${PATH_SOURCE} | grep ${fileName} | wc -l
			bye
			EOF`
	tmpName=`lftp << EOF
			open sftp://${ip}
			user ${user} ${pass}
			ls ${PATH_SOURCE} | grep ${fileName}
			bye
			EOF`
	SOURCE_FILE=${PATH_SOURCE}"/"$(echo ${tmpName} | cut -d' ' -f9)
	if [ ${countFile} == "0" ]; then
		#echo "File" ${PATH_SOURCE}"/"$(basename ${PATH_SOURCE})"_"${fileName}"00.zip not found ... !!"
		logECHO " [ERROR] ----> ${PATH_SOURCE}/$(basename ${PATH_SOURCE})_${fileName}00.zip not found ... !!"
		STOP_ERROR
	fi
	logECHO " ----> have file \"$(basename ${SOURCE_FILE})\""
}

GET_FILE_FROM_SERVER()
{
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
	FILE=${PATH_SCRIPT}"/"$(basename ${SOURCE_FILE})
	unzip -o ${FILE} > /dev/null 2>&1
	logECHO " UNZIP_FILE : $(basename ${FILE})"
}	

UNZIP_FILE()
{
	logECHO " UNZIP_FILE : $(basename ${1})"
	unzip $(${1})
}


FIX_NAME_FILE()
{
	logECHO " FIX_NAME_FILE"
	fileName=`echo ${1} | cut -d"." -f1`
	fileOutput=`ls | grep ${fileName} | grep \(`
	#echo $fileOutput
	fileFix=`cat ${CFG} | grep ${type} | cut -d'|' -f2 | sed "s/YYYYMMDDHH/${dateYMDH}/g"` 
	chmod 777 "${fileOutput}"
	mv "${fileOutput}" "${fileName}.csv"
	cp "${fileName}.csv" "${fileFix}.csv"
	FILE="${fileFix}.csv"
	logECHO " ----> from \"${fileOutput}\""
	logECHO " ----> to   \"${FILE}\""
}

REPLACE_NULL()
{
	logECHO " REPLACE_NULL"
	file=${1}
	cp ${file} ${file}.tmp
	cat ${file}.tmp | sed 's/\/0\,/\,/g' > ${file}
	rm ${file}.tmp
}

CHECK_COLUMN()
{
	logECHO " CHECK_COLUMN"
	file_CHECK_COLUMN=${1}
	columnSet=`cat ${CFG} | grep ${type} | cut -d'|' -f3`
	columnSouce=`cat $file_CHECK_COLUMN | grep -i BSCNAME | grep -i Cellname`
	IFS=',' read -r -a fColumnSet <<< "$columnSet"
	IFS=',' read -r -a fColumnSouce <<< "$columnSouce"
	aColumnSet=($(echo "${fColumnSet[@]}" | sed 's/ /\n/g' | awk '{print toupper($0)}' | sort))  
	aColumnSouce=($(echo "${fColumnSouce[@]}" | sed 's/ /\n/g' | awk '{print toupper($0)}' | sort)) 	
	#countAColumnSet=${#aColumnSet[@]}
	#countAColumnSouce=${#aColumnSouce[@]}
	i=0
	for tmp in ${aColumnSet[@]}; do
        #echo "aColumnSet["${i}"]"=${tmp} ":" ${aColumnSouce[${i}]}
		if [ ${aColumnSouce[${i}]} != ${aColumnSet[${i}]} ]
		then
			logECHO "[ERROR] ----> column [${aColumnSet[i]}] not match [${aColumnSouce[i]}]"
			END_SCRIPT#STOP_ERROR
		fi
		((i++))
	done
	tail -n+7 ${file_CHECK_COLUMN} | head -n-1 > "${file_CHECK_COLUMN}.tmp"
	mv ${file_CHECK_COLUMN}.tmp ${file_CHECK_COLUMN}
	logECHO " ----> colume is match"
}

SET_INSERT_NEW () 
{
	file_SET_INSERT_NEW=${1}
	columnSet_SET_INSERT_NEW=`cat ${CFG} | grep ${type} | cut -d'|' -f3`
	columnSouce_SET_INSERT_NEW=`cat $file_SET_INSERT_NEW | grep -i BSCNAME | grep -i Cellname`
	### cut string to array
	IFS=',' read -r -a fColumnSet_SET_INSERT_NEW <<< "$columnSet_SET_INSERT_NEW"
	IFS=',' read -r -a fColumnSouce_SET_INSERT_NEW <<< "$columnSouce_SET_INSERT_NEW"
	aColumnSet=($(echo "${fColumnSet_SET_INSERT_NEW[@]}" | sed 's/ /\n/g' | awk '{print toupper($0)}'))  
	aColumnSouce=($(echo "${fColumnSouce_SET_INSERT_NEW[@]}" | sed 's/ /\n/g' | awk '{print toupper($0)}')) 
	### find key index of column
	for tmp in ${!aColumnSet[@]}; do
		for tmp2 in ${!aColumnSouce[@]}; do
			if [ ${aColumnSet[${tmp}]} == ${aColumnSouce[${tmp2}]} ]
			then
				keyIndex[${tmp}]=${tmp2}
				break;
			else	
				keyIndex[${tmp}]=999
			fi
		done
	done
	#declare -p keyIndex ### print value for debug
	kSet=$(echo ${!keyIndex[@]} | sed 's/ //g')
	kSource=$(echo ${keyIndex[@]} | sed 's/ //g')
	if [ ${kSet} == ${kSource} ] ; then
		logECHO " ----> Header is Same"	
	else
		logECHO " ----> Header not Same"
	fi
	tail -n+8 ${file_SET_INSERT_NEW} | head -n-2 > "${file_SET_INSERT_NEW}.tmp"
	mv ${file_SET_INSERT_NEW}.tmp ${file_SET_INSERT_NEW}
	echo ${columnSet_SET_INSERT_NEW} > ${file_SET_INSERT_NEW}.run
	chmod 755 ${file_SET_INSERT_NEW}
	while read dataLine ; do
		IFS=',' read -r -a dataColumn <<< "${dataLine}"
		strTmp=""
		langeArray=$(expr ${#keyIndex[@]} - 1)
		for keySelect in ${!keyIndex[@]}; do
			strTmp=${strTmp}${dataColumn[${keyIndex[${keySelect}]}]}
			if [ ${keySelect} -lt ${langeArray} ] ; then 
				strTmp=${strTmp}","
			fi
		done
		echo ${strTmp} >> ${file_SET_INSERT_NEW}.run
	done < ${file_SET_INSERT_NEW}
	
	logECHO " INSERT_TO_NEW_FILE"
}

STOP_ERROR ()
{
	logECHO " ====== Script is top running.... ======"
	exit 0
}

END_SCRIPT () 
{
	logECHO " Stop: $(date "+%Y-%m-%d %H:%M:%S")"
	logECHO "--------------------------------------------------------"
	logECHO "... ${mode} GetSource Complete ...                      "
	logECHO "--------------------------------------------------------"
	logECHO " "
}

MOVE_FILE_TO_TARGET () 
{
	file_MOVE_FILE_TO_TARGET=${1}
	target_MOVE_FILE_TO_TARGET=${2}
	mv ${file_MOVE_FILE_TO_TARGET}.run ${target_MOVE_FILE_TO_TARGET}/${file_MOVE_FILE_TO_TARGET}
}


SET_LOG_READY () 
{
	[ $mode == 'a' ] || [ $mode == 'A' ] && mode="Auto" || mode="Manual"
	logECHO "--------------------------------------------------------"
	logECHO " Start ${mode} Get Source                               "
	logECHO "--------------------------------------------------------"
	logECHO " Start: $(date "+%Y-%m-%d %H:%M:%S")"
	logECHO " PERIOD: ${period}"
	logECHO " KEYWORD: ${dateYMDH}"
	logECHO " IP ADDRESS: ${IP}"
	logECHO " SOURCE PATH: ${PATH_SOURCE}"
	logECHO " TARGET PATH: ${PATH_TARGET}"
	logECHO " TMP PATH: ${PATH_TMP}"
	logECHO " LOG PATH: ${PATH_LOG}"
	logECHO " CONFIG FILE: ${CFG}"
}
######################################################################
###### #################################################### ##########
#                           Main Program                             #
#						 Create by Chatchai							 #
###### #################################################### ##########
######################################################################

#RUN => *.sh M 2017082806 60 PMS_GSM_GCELL_60

CHECK_PATH "TARGET PATH" ${PATH_TARGET}
CHECK_PATH "TMP PATH" ${PATH_TMP}
CHECK_PATH "LOG PATH" ${PATH_LOG}
SET_LOG_READY 
CHECK_FILE_FROM_SERVER ${IP} ${USER} ${PASSWORD} ${dateYMDH}
GET_FILE_FROM_SERVER ${IP} ${USER} ${PASSWORD} ${SOURCE_FILE} 
FIX_NAME_FILE $(basename ${FILE})
dos2unix ${FILE} > /dev/null 2>&1
REPLACE_NULL ${FILE}
#CHECK_COLUMN ${FILE}
SET_INSERT_NEW ${FILE}
MOVE_FILE_TO_TARGET ${FILE} ${PATH_TARGET}
MOVE_FILE_TMP
END_SCRIPT

exit 0


