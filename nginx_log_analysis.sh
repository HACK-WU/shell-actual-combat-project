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
function daily_pv {				#统计指定日期的PV量
	echo -e "\033[33m"
  	read -p "please input a or two  date (09/Jul/2020:10:12:07): "  dates
	echo "------------------------------------------------------------"
	echo -e "\033[0m"
	local Year=$(date +"%Y")
	local Mon=$(date +"%b" |grep "月" &>/dev/null  &&  changeToENG `date +"%b"`||echo `date +"%b"` )	#将月份改为英文缩写
	local Day=$(date +"%d")
	local num=0
	for item in $dates
	do
		local date_array[++num]=$item
	done
	case $num in
	0)						#默认状态，没有写入参数
		local date="$Day/$Mon/$Year"
        local count=$(grep "$date" $log_path|wc -l) 
		echo "目前今日的PV量为： $count"
	 	;;
	1) 						#写入了一个参数
		local date=$dates
		local count=$(grep "$date" $log_path | wc -l)
		echo "$date 这个时刻的访问量为： $count"
		;;

	2) 						#写入了两个参数
		local start_date=${date_array[1]}
		local end_date=${date_array[2]}
		local count=$(awk '{str=$4; sub(/\[/,"",str); if(str<="'''$end_date'''" && str>="'''$start_date'''") print $0}' $log_path|wc -l) 		     	
		echo "从$start_date到$end_date的PV量为： $count"	
		;;	
	*) 						#参数过多
		echo "参数过多，最多支持两个!!!!"
		sleep 1
		return 1
		;;
	esac

	echo "----------------------------------------------------------------------"
	
}

daily_pv	
