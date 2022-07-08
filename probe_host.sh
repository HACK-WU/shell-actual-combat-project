#!/usr/bin/bash
# author:hackwu
# 2022/7/8
# 探测主机是否存活

set -u
ip_list=(
	192.168.23.48  
	192.168.23.21
	192.168.23.43
	192.168.23.11
)

function ping_host {
	if ping -c1 -W1 $1 &>/dev/null ;then
		echo "$1 is alive"
		continue
	fi
}

for ip in ${ip_list[*]}
do
	ping_host $ip
	ping_host $ip
	ping_host $ip
	echo -e "\033[31m主机：$ip id dead\033[0m"	
done
