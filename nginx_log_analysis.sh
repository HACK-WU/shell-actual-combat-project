#!/usr/bin/bash
# author:hackwu
# 2022/7/9
# Nginx 日志分析

set -u
log_path=/var/log/nginx/access.log
function changeToENG {
	case $1 in
		1月)	echo "Jan" ;;
		2月)	echo "Feb" ;;
		3月)    echo "Mar" ;;
		4月)    echo "Apr" ;;
		5月)	echo "May" ;;
		6月)	echo "Jun" ;;
		7月)	echo "Jul" ;;
		8月)	echo "Aug" ;;
		9月)	echo "Sep" ;;
		10月) 	echo "Oct" ;;
		11月)	echo "Nov" ;;
		12月)	echo "Dec" ;;
	esac
}
function daily_pv {
	echo -e "\033[33m"
  	read -p "please input a  date (09/Jul/2020:10:12:07): "  date
	echo "------------------------------------------------------------"
	echo -e "\033[0m"
	local Year=$(date +"%Y")
	local Mon=$(date +"%b" |grep "月" &>/dev/null  &&  changeToENG `date +"%b"`||echo `date +"%b"` )	#将月份改为英文缩写
	local Day=$(date +"%d")
	[ ${#date} -gt 0 ] && local date=$date || local date="$Day/$Mon/$Year"
	local today=$date		#当日的日期
	local result=$(grep "$today" $log_path)
	IFS=$'\n'
	for item in $result
	do
		echo "$item"
		echo "---------------------------------------------------------------------------------------------------"
	done
}

daily_pv	
