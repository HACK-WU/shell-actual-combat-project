#!/usr/bin/bash
# author: hackwu
# 2022/7/6
# 查询系统信息的脚本

set -u
PS3="Your choice is : "
function os_check {
	if [ -e /etc/redhat-release ];then	#判断linux发行版本
		REDHAT=$(cat /etc/redhat-release  |cut -d " " -f1 )	#redhat版本
	else	
		DEBIAN=$(cat /etc/issue  |cut -d " " -f1)	#ubuntu	版本
	fi
	
	if [ "$REDHAT" == "CentOS" -o "$REDHAT" == "Red" ];then	#如果redhat
		P_M=yum			#包管理工具使用yum
	elif [ "$DEBIAN" == "Ubuntu" -o "$DEBIAN" == "ubuntu" ];then		#如果是ubutnu
		P_M=apt-get	
	else
		echo "Operating system does not support"
		echo "即将退出程序……"
		sleep 2
		exit 1		#退出 并返回1 
	fi
}
os_check
 
if [ "$LOGNAME" != "root" ] ;then
	echo "Please use root account operation"
	echo "即将退出程序……"
	sleep 2
	exit 1
fi

if ! which vmstat &>/dev/null ;then
	echo "vmstat command not found,now will install it"
	sleep 1
 	$P_M  install procps -y
	echo "-------------------------------------------------"
fi

if ! which iostat &>/dev/null;then
	echo "iostat command not found,now will install it"
	sleep 1
	$P_M install -y sysstat
	echo "----------------------------------------------"
fi

function cpu_load {
	 #CPU利用率与负载
       echo "-----------------------------"
       local i=1
       while [[ $i -le 3 ]]
       do
           echo -e "\033[32m 参考值${i}\033[0m"
           UTIL=$(vmstat |awk '{if(NR==3) print 100-$15"%"}') #CPU使用率
           USER=$(vmstat |awk '{if(NR==3) print $13"%"}') #CPU用户使用率
           SYS=$(vmstat |awk '{if(NR==3) print $14"%"}')    #CPU系统使用率
           IOWAIT=$(vmstat |awk '{if(NR==3) print $16"%"}') #等待I/O所消耗的CPU的百分比                    
           echo "Util: $UTIL"
           echo "User user: $USER"
           echo "System use: $SYS"
           echo "I/O wait $IOWAIT"
           let i++
           sleep 1
        done

}

function disk_load { 		#磁盘使用率
	#硬盘I/O负载
	echo "------------------------------------"
	for i in {1..3}
	do
		echo -e "\033[32m 参考值$i\033[0m"
		UTIL=$(iostat -x -k |awk '/^[s|v]da/{OFS=": "; print $1,$NF"%"}')		#CPU利用率
		READ=$(iostat -x -k |awk '/^[s|v]da/{OFS=": "; print $1,$6"KB"}')
		WRITE=$(iostat -x -k |awk '/^[s|v]da/{OFS=": "; print $1,$7"KB"}')
		IOWAIT=$(vmstat |awk '{if(NR==3)print $16"%"}' )
		echo -e "UTIL: \n\t$UTIL"
		echo -e "I/O Wait: \n\t$IOWAIT"
		echo -e "Read/s: \n\t$READ"
		echo -e "Write/s: \n\t$WRITE"
		sleep 1			
	done	
}

function disk_use {
	#磁盘利用率
	local DEFAULT_USE_RATE=90	#默认磁盘使用率
	local DISK_LOG=/tmp/disk_use.tmp
	local DISK_TOTAL=$(fdisk -l |awk '/^磁盘.*字节/||/^Disk.*bytes/ {str=$3;sub(/,/,"",str);print $2,str}')
	local ROW=$(df -h|awk '/^\/dev/{print $0}')	#筛选出有哪些行符合条件
	local DEFAULT_IFS=$IFS
	local IFS=$'\n'
	echo "------------------------------"
	for item in $ROW
	do
		local USE_RATE=$(echo $item |awk '{print int($5)}')
		if [ $USE_RATE -gt $DEFAULT_USE_RATE ];then
		local PART=$(echo $item|awk '{print $6}')
			echo "$PART 下使用率：$USE_RATE%" >> $DISK_LOG	#将超出使用率的目录保存到文件中
		fi
	done
	echo "-------------------------------"
	echo -e "Disk total:\n$DISK_TOTAL"
	if [ -f $DISK_LOG ];then
		echo "------------------------------"
		cat $DISK_LOG
		echo "------------------------------"
		rm -f $DISK_LOG
	else
		echo "------------------------------"
		echo "Disk use rate no than $DEFAULT_USE_RATE% of the partition"
	fi
}
function disk_inode {   		#
	local INODE_LOG=/tmp/inode_use.tmp
    local INODE_USE=$(df -i|grep "^/dev")
    local DEFAULT_INODE_USE=90
	local IFS=$'\n'
    for item in $INODE_USE
    do
		local USE_RATE=$( echo $item |awk '{num=$5;sub(/%/,"",num);print num}')
        local PART=$(echo $item |awk '{print $6}')
		if [ $USE_RATE -gt $DEFAULT_INODE_USE ];then
			echo "$PART下inode利用率为： $USE_RATE" >> $INODE_LOG
		fi	
    done
	echo "--------------------------------"
	if [ -f $INODE_LOG ];then 
		cat $INODE_LOG
		rm -f $INODE_LOG
	else
		echo "Inode use rate no than $DEFAULT_INODE_USE of the partition"
	fi
		
}
function mem_use { 
	#内存使用率
    echo "------------------------"
    local MEM_TOTAL=$(free -h |awk '{if(NR==2) print $2 }')
    local USE=$(free -h |awk '{if(NR==2) print $3}')
    local FREE=$(free -h |awk '{if(NR==2) print $4}')
    local CACHE=$(free -h |awk '{if(NR==2) print $6}')

    echo "Total: $MEM_TOTAL"
    echo "Use: $USE"
    echo "Free: $FREE"
    echo "Cache: $CACHE"
}
function tcp_status {
	#网络连接状态
    echo "----------------------"
    local COUNT=$(ss -ant |awk '!/State/{status[$1]++} END{OFS=": ";for(i in status) print i,status[i] }')
    echo -e  "TCP connection status:\n$COUNT"
    echo "----------------------"
}
function cpu_top10 {
	#查看占用CPU前10的进程
	while :
	do
	local ps_info=$(ps aux | awk 'BEGIN{PID=0}
		{
			if($3>0.1){
				PID++;
				print  PID,"PID:"$2,"CPU:"$3"%-->"$NF
			}	
		}')
	local IFS=$'\n'
	echo "------------------------------"
	[ -z $ps_info ] && echo "Now have no process using the CPU!"
	local process[0]="quit"
	for item in $ps_info
	do
		echo "$item"
		local NUM=$(echo "$item" |awk '{print $1}')
		local PID=$(echo "$item" |awk '{print $2}'|cut -d ":" -f2)
		local process[$NUM]=$PID	
	done
		echo -e "-------------------------------------\n"
		read -p "You can kill a process by number[1,2,3..] and 0 for quit: " number
		
		if [ $number -eq 0 ] ;then
			echo "即将退出。。。"
			sleep 1
			break;
		fi
 	    if [[ $number =~ [1-9]+ ]]&&[ ${#process[$number]} -gt 0 ];then    #长度大于0,
			kill -9 ${process[$number]}
			sleep 1
		else
			echo "输入错误"
			sleep 1
		fi
	done
}
function mem_top10 {
	echo ""
}
function traffic {
		#查看网路流量
	while :
	do
	    read -p "Please enter the network card name(Default ens33i,0 for quit): " card_name
		[ ${#card_name} -gt 0 ]|| card_name="ens33"		#检查输入是否为空，为空就是默认值
	    [ $card_name -eq 0 ] &>/dev/null  && break 			#退出	
		if  ifconfig $card_name  &>/dev/null ;then
			local RX_packets_01=$(ifconfig $card_name|grep "RX.*pack"|awk '{print $5}')
			local TX_packets_01=$(ifconfig $card_name|grep "TX.*pack"|awk '{print $5}')
			sleep 1
			local RX_packets_02=$(ifconfig $card_name|grep "RX.*pack"|awk '{print $5}')
			local TX_packets_02=$(ifconfig $card_name|grep "TX.*pack"|awk '{print $5}')
		 	local IN_pack=$(( $RX_packets_02 - $RX_packets_01 ))
			local OUT_pack=$(($TX_packets_02 - $TX_packets_01 ))
			echo "-----------------------------------"
			echo "接收数据包:$(echo $IN_pack|awk '{printf "%.2fMB/s",'''$IN_pack'''/1024/1024}' )"
			echo "发送数据包:$(echo $OUT_pack|awk '{printf "%.2fMB/s",'''$OUT_pack'''/1024/1024}' )"
			echo "-----------------------------------"
		else 
			echo "Error card name!!"	
	    fi	
	done
}

while :
do
	echo ""
	select  input in  cpu_load disk_use disk_inode disk_load mem_use  tcp_status cpu_top10 mem_top10 traffic quit
	do
		case $input in 
			cpu_load) cpu_load ; break  ;;	#调用函数
			disk_load) disk_load ; break  ;;
			disk_use) disk_use ; break  ;;
			disk_inode) disk_inode ; break ;;
			mem_use) mem_use ; break ;;
			tcp_status) tcp_status ; break ;;
			cpu_top10) cpu_top10 ; break ;;
			traffic) traffic ; break ;; 
			quit)
				exit 0
			;;	
		esac
	done
done

echo "------------------------------------"
echo "finished"

















