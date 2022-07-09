#!/usr/bin/bash
# author:hackwu
# 2022/7/9
# Nginx 日志分析

# 用法示例：
# pv(ip) 				：默认查询当日pv量或者查询的ip的访问次数
# pv(ip) 09/Jul/2022	: 查询09/Jul/2022 这一天的Pv量,或者查询ip的访问次数
# pv 09/Jul/2022 10/Jul/2022	:查询9号到10号这之间的,或者查询ip的访问次数
# ip10 	:表示查询当日访问次数最多的前10个IP,具体的数字可以任意指定
# ip100 09/Jul/2022 :查询这一天的，访问次数最多的前100个ip

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
			return 0
		fi
		
		if [[ "$command_type" == "pv" && "$num" -eq 3  ]];then
			local count=$(awk '{str=$4; sub(/\[/,"",str); if(str<="'''$end_date'''" && str>="'''$start_date'''") print $0}' $log_path|wc -l)
        echo "从$start_date到$end_date的PV量为： $count"			
			return 0
		fi
#	--------------------------------IP_TOP-------------------------
		local top_num="$command_type"
              top_num="${command_type#ip}"
		[ -z $top_num ] && top_num=10000

		if [[ "$command_type" =~ "ip" && "$num" -lt 3  ]];then
			local result=$(grep "$date" $log_path|awk '{ips[$1]++} END{num=1;for(ip in ips)if(num<='''$top_num'''){print ip,ips[ip];num++}}' | sort -k2 -rn)
			[ "$num" -eq 1 ] && echo -e "今日截止$date:$(date +"%T")访问最多的几个ip是:\n$result"  
            [ "$num" -eq 2 ] && echo -e "$date 这个时刻,访问最多的几个ip是:\n$result"
		fi
		
		if [[ "$command_type" =~ "ip" && "$num" -eq 3  ]];then
            local result=$(awk '
				{str=$4; sub(/\[/,"",str);if(str<="'''$end_date'''" && str>="'''$start_date'''") ips[$1]++}
				END{num=1; for(ip in ips)if(num<='''$top_num'''){ print ip,ips[ip];num++}}
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
