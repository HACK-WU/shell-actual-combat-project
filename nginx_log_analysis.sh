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
	function exe {
#	------------------------------PV------------------------------
		if [[ "$command_type" == "pv" && "$num" -lt 3  ]];then		#
			local count=$(grep "$date" $log_path|wc -l)
			[ "$num" -eq 1 ] && echo "今日截止$date:$(date +"%T") 的PV量为： $count"
			[ "$num" -eq 2 ] && echo "$date 这个时刻的访问量为： $count"
		fi
		
		if [[ "$command_type" == "pv" && "$num" -eq 3  ]];then
			local count=$(awk '{str=$4; sub(/\[/,"",str); if(str<="'''$end_date'''" && str>="'''$start_date'''") print $0}' $log_path|wc -l)
        echo "从$start_date到$end_date的PV量为： $count"			
		fi
#	--------------------------------IP_TOP-------------------------
		if [[ "$command_type" == "ip" && "$num" -lt 3  ]];then
			local result=$(grep "$date" $log_path|awk '{ips[$1]++ } END{for(ip in ips) print ip,ips[ip]}' | sort -k2 -rn)
			[ "$num" -eq 1 ] && echo -e "今日截止$date:$(date +"%T")访问最多的几个ip是:\n$result"  
            [ "$num" -eq 2 ] && echo -e "$date 这个时刻,访问最多的几个ip是:\n$result"
		fi
		
		if [[ "$command_type" == "ip" && "$num" -eq 3  ]];then
            echo "执行了"
            local result=$(awk '
				{str=$4; sub(/\[/,"",str);if(str<="'''$end_date'''" && str>="'''$start_date'''") ips[$1]++}
				END{ for(ip in ips) print ip,ips[ip]}
				' $log_path  |sort -k2 -rn)
        	echo  -e "从$start_date到$end_date访问最多的几个ip是：\n$result"            
        fi	

	}
		
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
		local date_array[num++]=$item
	done
	case $num in
	0)
		echo "请输入ip或者pv："
		;;
	1)						#默认状态，没有写入参数
		local command_type="${date_array[0]}"
		local date="$Day/$Mon/$Year"
		exe	
	 	;;
	2) 						#写入了一个参数
		local command_type="${date_array[0]}"
		local date=${date_array[1]}
		exe
		;;

	3) 						#写入了两个参数
		local command_type="${date_array[0]}"
		local start_date=${date_array[1]}
		local end_date=${date_array[2]}
		exe
		;;	
	*) 						#参数过多
		echo "参数过多，最多支持三个!!!!"
		sleep 1
		return 1
		;;
	esac

	echo "----------------------------------------------------------------------"
	
}

daily_pv	
