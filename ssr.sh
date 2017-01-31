#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6/Debian/Ubuntu 14.04+
#	Description: Install the ShadowsocksR server
#	Version: 1.1.7
#	Author: Toyo
#	Blog: https://doub.io/ss-jc42/
#=================================================

#ssr_pid="/var/run/shadowsocks.pid"
ssr_file="/etc/shadowsocksr"
config_file="/etc/shadowsocksr/config.json"
config_user_file="/etc/shadowsocksr/user-config.json"
server_file="/etc/shadowsocksr/shadowsocks"
Libsodiumr_file="/root/libsodium"
Libsodiumr_ver="1.0.11"

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	#bit=`uname -m`
}
#获取用户账号信息
getUser(){
	# 获取IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	[ -z "$ip" ] && ip="VPS_IP"
	port=`jq '.server_port' ${config_user_file}`
	password=`jq '.password' ${config_user_file} | sed 's/^.//;s/.$//'`
	method=`jq '.method' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol=`jq '.protocol' ${config_user_file} | sed 's/^.//;s/.$//'`
	obfs=`jq '.obfs' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol_param=`jq '.protocol_param' ${config_user_file} | sed 's/^.//;s/.$//'`
}
#设置用户账号信息
setUser(){
	#设置端口
	while true
	do
	echo -e "请输入ShadowsocksR账号的 端口 [1-65535]:"
	read -p "(默认端口: 2333):" ssport
	[ -z "$ssport" ] && ssport="2333"
	expr ${ssport} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${ssport} -ge 1 ] && [ ${ssport} -le 65535 ]; then
			echo
			echo "——————————————————————————————"
			echo -e "	端口 : \033[41;37m ${ssport} \033[0m"
			echo "——————————————————————————————"
			echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
	#设置密码
	echo "请输入ShadowsocksR账号的 密码:"
	read -p "(默认密码: doub.io):" sspwd
	[ -z "${sspwd}" ] && sspwd="doub.io"
	echo
	echo "——————————————————————————————"
	echo -e "	密码 : \033[41;37m ${sspwd} \033[0m"
	echo "——————————————————————————————"
	echo
	#设置加密方式
	echo "请输入数字 来选择ShadowsocksR账号的 加密方式:"
	echo "1. rc4-md5"
	echo "2. aes-256-ctr"
	echo "3. aes-256-cfb"
	echo "4. aes-256-cfb8"
	echo "5. camellia-256-cfb"
	echo "6. chacha20"
	echo "7. chacha20-ietf"
	echo
	read -p "(默认加密方式: 3. aes-256-cfb):" ssmethod
	[ -z "${ssmethod}" ] && ssmethod="3"
	if [ ${ssmethod} == "1" ]; then
		ssmethod="rc4-md5"
	elif [ ${ssmethod} == "2" ]; then
		ssmethod="aes-256-ctr"
	elif [ ${ssmethod} == "3" ]; then
		ssmethod="aes-256-cfb"
	elif [ ${ssmethod} == "4" ]; then
		ssmethod="aes-256-cfb8"
	elif [ ${ssmethod} == "5" ]; then
		ssmethod="camellia-256-cfb"
	elif [ ${ssmethod} == "6" ]; then
		ssmethod="chacha20"
	elif [ ${ssmethod} == "7" ]; then
		ssmethod="chacha20-ietf"
	else
		ssmethod="aes-256-cfb"
	fi
	echo
	echo "——————————————————————————————"
	echo -e "	加密方式 : \033[41;37m ${ssmethod} \033[0m"
	echo "——————————————————————————————"
	echo
	#设置协议
	echo "请输入数字 来选择ShadowsocksR账号的 协议( auth_aes128_* 以后的协议不再支持 兼容原版 ):"
	echo "1. origin"
	echo "2. verify_sha1"
	echo "3. auth_sha1_v2"
	echo "4. auth_sha1_v4"
	echo "5. auth_aes128_md5"
	echo "6. auth_aes128_sha1"
	echo
	read -p "(默认协议: 4. auth_sha1_v4):" ssprotocol
	[ -z "${ssprotocol}" ] && ssprotocol="4"
	if [ ${ssprotocol} == "1" ]; then
		ssprotocol="origin"
	elif [ ${ssprotocol} == "2" ]; then
		ssprotocol="verify_sha1"
	elif [ ${ssprotocol} == "3" ]; then
		ssprotocol="auth_sha1_v2"
	elif [ ${ssprotocol} == "4" ]; then
		ssprotocol="auth_sha1_v4"
	elif [ ${ssprotocol} == "5" ]; then
		ssprotocol="auth_aes128_md5"
	elif [ ${ssprotocol} == "6" ]; then
		ssprotocol="auth_aes128_sha1"
	else
		ssprotocol="auth_sha1_v4"
	fi
	echo
	echo "——————————————————————————————"
	echo -e "	协议 : \033[41;37m ${ssprotocol} \033[0m"
	echo "——————————————————————————————"
	echo
	#设置混淆
	echo "请输入数字 来选择ShadowsocksR账号的 混淆:"
	echo "1. plain"
	echo "2. http_simple"
	echo "3. http_post"
	echo "4. random_head"
	echo "5. tls1.2_ticket_auth"
	echo
	read -p "(默认混淆: 5. tls1.2_ticket_auth):" ssobfs
	[ -z "${ssobfs}" ] && ssobfs="5"
	if [ ${ssobfs} == "1" ]; then
		ssobfs="plain"
	elif [ ${ssobfs} == "2" ]; then
		ssobfs="http_simple"
	elif [ ${ssobfs} == "3" ]; then
		ssobfs="http_post"
	elif [ ${ssobfs} == "4" ]; then
		ssobfs="random_head"
	elif [ ${ssobfs} == "5" ]; then
		ssobfs="tls1.2_ticket_auth"
	else
		ssobfs="tls1.2_ticket_auth"
	fi
	echo
	echo "——————————————————————————————"
	echo -e "	混淆 : \033[41;37m ${ssobfs} \033[0m"
	echo "——————————————————————————————"
	echo
	#询问是否设置 混淆 兼容原版
	if [ ${ssprotocol} != "origin" ]; then
		if [ ${ssobfs} != "plain" ]; then
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				read -p "是否设置 协议/混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
				[ -z "${yn1}" ] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible" && ssprotocol=${ssprotocol}"_compatible"
			else
				read -p "是否设置 混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
				[ -z "${yn1}" ] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
			fi
		else
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				read -p "是否设置 协议 兼容原版 ( _compatible )? [Y/n] :" yn1
				[ -z "${yn1}" ] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssprotocol=${ssprotocol}"_compatible"
			fi
		fi
	else
		if [ ${ssobfs} != "plain" ]; then
			read -p "是否设置 混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
			[ -z "${yn1}" ] && yn1="y"
			[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
		fi
	fi
	if [ ${ssprotocol} != "origin" ]; then
		while true
		do
		echo
		echo -e "请输入 ShadowsocksR账号欲限制的链接IP数(\033[42;37m auth_* 系列协议 不兼容原版才有效 \033[0m)"
		read -p "(回车 默认无限):" ssprotocol_param
		[ -z "$ssprotocol_param" ] && ssprotocol_param=0 && break
		expr ${ssprotocol_param} + 0 &>/dev/null
		if [ $? -eq 0 ]; then
			if [ ${ssprotocol_param} -ge 1 ] && [ ${ssprotocol_param} -le 99999 ]; then
				echo
				echo "——————————————————————————————"
				echo -e "	链接设备数 : \033[41;37m ${ssprotocol_param} \033[0m"
				echo "——————————————————————————————"
				echo
				break
			else
				echo "输入错误，请输入正确的数字 !"
			fi
		else
			echo "输入错误，请输入正确的数字 !"
		fi
		done
	fi
	#最后确认
	echo
	echo "——————————————————————————————"
	echo "      请检查Shadowsocks账号配置是否有误 !"
	echo
	echo -e "	端口 : \033[41;37m ${ssport} \033[0m"
	echo -e "	密码 : \033[41;37m ${sspwd} \033[0m"
	echo -e "	加密方式 : \033[41;37m ${ssmethod} \033[0m"
	echo -e "	协议 : \033[41;37m ${ssprotocol} \033[0m"
	echo -e "	混淆 : \033[41;37m ${ssobfs} \033[0m"
	echo -e "	设备数限制 : \033[41;37m ${ssprotocol_param} \033[0m"
	echo "——————————————————————————————"
	echo
	read -p "请按任意键继续，如有配置错误请使用 Ctrl+C 退出。" var
	[ "${ssprotocol_param}" = 0 ] && ssprotocol_param=""
}
#显示用户账号信息
viewUser(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [ -z "${PID}" ]; then
		ssr_status="\033[41;37m 	当前状态： \033[0m ShadowsocksR 没有运行！"
	else
		ssr_status="\033[42;37m 	当前状态： \033[0m ShadowsocksR 正在运行！"
	fi
	now_mode=`jq '.port_password' ${config_user_file}`
	if [ "${now_mode}" = "null" ]; then
		getUser
		
		SSprotocol=`echo ${protocol} | awk -F "_" '{print $NF}'`
		SSobfs=`echo ${obfs} | awk -F "_" '{print $NF}'`
		if [ ${protocol} = "origin" ]; then
			if [ ${obfs} = "plain" ]; then
				SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
				SSurl="ss://"${SSbase64}
				SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
				ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
				ssr_link=""
			else
				if [ ${SSobfs} != "compatible" ]; then
					ss_link=""
				else
					SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
					SSurl="ss://"${SSbase64}
					SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
					ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
				fi
			fi
		else
			if [ ${SSprotocol} != "compatible" ]; then
				ss_link=""
			else
				if [ ${SSobfs} != "compatible" ]; then
					if [ ${SSobfs} = "plain" ]; then
						SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
						SSurl="ss://"${SSbase64}
						SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
						ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
					else
						ss_link=""
					fi
				else
					SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
					SSurl="ss://"${SSbase64}
					SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
					ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
				fi
			fi
		fi
		SSRprotocol=`echo ${protocol} | sed 's/_compatible//g'`
		SSRobfs=`echo ${obfs} | sed 's/_compatible//g'`
		SSRPWDbase64=`echo -n "${password}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
		SSRbase64=`echo -n "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
		SSRurl="ssr://"${SSRbase64}
		SSRQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSRurl}
		ssr_link="	SSR链接: \033[41;37m ${SSRurl} \033[0m \n	SSR二维码: \033[41;37m ${SSRQRcode} \033[0m \n "
		[ -z ${protocol_param} ] && protocol_param="0"
		clear
		echo "############################################################"
		echo
		echo -e "	你的ShadowsocksR 账号配置 : "
		echo
		echo -e "	I P: \033[41;37m ${ip} \033[0m"
		echo -e "	端口: \033[41;37m ${port} \033[0m"
		echo -e "	密码: \033[41;37m ${password} \033[0m"
		echo -e "	加密方式: \033[41;37m ${method} \033[0m"
		echo -e "	协议: \033[41;37m ${protocol} \033[0m"
		echo -e "	混淆: \033[41;37m ${obfs} \033[0m"
		echo -e "	设备数限制: \033[41;37m ${protocol_param} \033[0m"
		echo -e "${ss_link}"
		echo -e "${ssr_link}"
		echo -e "\033[42;37m 提示： \033[0m"
		echo -e "浏览器中，打开二维码链接，就可以看到二维码图片。"
		echo -e "协议和混淆后面的[ _compatible ]，指的是兼容原版Shadowsocks协议/混淆。"
		echo
		echo -e ${ssr_status}
		echo
		echo "############################################################"
	else
		getUser
		[ -z ${protocol_param} ] && protocol_param="0"
		clear
		echo "############################################################"
		echo
		echo -e "	你的ShadowsocksR 账号配置 : "
		echo
		echo -e "	I P: \033[41;37m ${ip} \033[0m"
		echo -e "	加密方式: \033[41;37m ${method} \033[0m"
		echo -e "	协议: \033[41;37m ${protocol} \033[0m"
		echo -e "	混淆: \033[41;37m ${obfs} \033[0m"
		echo -e "	设备数限制: \033[41;37m ${protocol_param} \033[0m"
		echo
		user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		[[ ${socat_total} = "0" ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现 多端口用户，请检查 !" && exit 1
		user_id=0
		check_sys
		if [[ ${release} = "centos" ]]; then
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_id=$[$user_id+1]	
			
				SSprotocol=`echo ${protocol} | awk -F "_" '{print $NF}'`
				SSobfs=`echo ${obfs} | awk -F "_" '{print $NF}'`
				if [ ${protocol} = "origin" ]; then
					if [ ${obfs} = "plain" ]; then
						SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
						SSurl="ss://"${SSbase64}
						SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
						ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
						ssr_link=""
					else
						if [ ${SSobfs} != "compatible" ]; then
							ss_link=""
						else
							SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
							SSurl="ss://"${SSbase64}
							SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
							ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
						fi
					fi
				else
					if [ ${SSprotocol} != "compatible" ]; then
						ss_link=""
					else
						if [ ${SSobfs} != "compatible" ]; then
							if [ ${SSobfs} = "plain" ]; then
								SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
								SSurl="ss://"${SSbase64}
								SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
								ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
							else
								ss_link=""
							fi
						else
							SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
							SSurl="ss://"${SSbase64}
							SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
							ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
						fi
					fi
				fi
				SSRprotocol=`echo ${protocol} | sed 's/_compatible//g'`
				SSRobfs=`echo ${obfs} | sed 's/_compatible//g'`
				SSRPWDbase64=`echo -n "${user_password}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
				SSRbase64=`echo -n "${ip}:${user_port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
				SSRurl="ssr://"${SSRbase64}
				SSRQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSRurl}
				ssr_link="	SSR链接: \033[41;37m ${SSRurl} \033[0m \n	SSR二维码: \033[41;37m ${SSRQRcode} \033[0m \n "
			
				echo -e "	—————————— \033[42;37m 用户 ${user_id} \033[0m ——————————"
				echo -e "	端口: \033[41;37m ${user_port} \033[0m"
				echo -e "	密码: \033[41;37m ${user_password} \033[0m"
				echo -e "${ss_link}"
				echo -e "${ssr_link}"
			done
		else
			for((integer = ${user_total}; integer >= 1; integer--))
			do
				user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				user_id=$[$user_id+1]	
			
				SSprotocol=`echo ${protocol} | awk -F "_" '{print $NF}'`
				SSobfs=`echo ${obfs} | awk -F "_" '{print $NF}'`
				if [ ${protocol} = "origin" ]; then
					if [ ${obfs} = "plain" ]; then
						SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
						SSurl="ss://"${SSbase64}
						SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
						ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
						ssr_link=""
					else
						if [ ${SSobfs} != "compatible" ]; then
							ss_link=""
						else
							SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
							SSurl="ss://"${SSbase64}
							SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
							ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
						fi
					fi
				else
					if [ ${SSprotocol} != "compatible" ]; then
						ss_link=""
					else
						if [ ${SSobfs} != "compatible" ]; then
							if [ ${SSobfs} = "plain" ]; then
								SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
								SSurl="ss://"${SSbase64}
								SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
								ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
							else
								ss_link=""
							fi
						else
							SSbase64=`echo -n "${method}:${user_password}@${ip}:${user_port}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
							SSurl="ss://"${SSbase64}
							SSQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSurl}
							ss_link="	SS链接: \033[41;37m ${SSurl} \033[0m \n	SS二维码: \033[41;37m ${SSQRcode} \033[0m"
						fi
					fi
				fi
				SSRprotocol=`echo ${protocol} | sed 's/_compatible//g'`
				SSRobfs=`echo ${obfs} | sed 's/_compatible//g'`
				SSRPWDbase64=`echo -n "${user_password}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
				SSRbase64=`echo -n "${ip}:${user_port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}" | base64 | sed ':a;N;s/\n/ /g;ta' | sed 's/ //g'`
				SSRurl="ssr://"${SSRbase64}
				SSRQRcode="http://pan.baidu.com/share/qrcode?w=300&h=300&url="${SSRurl}
				ssr_link="	SSR链接: \033[41;37m ${SSRurl} \033[0m \n	SSR二维码: \033[41;37m ${SSRQRcode} \033[0m \n "
			
				echo -e "	—————————— \033[42;37m 用户 ${user_id} \033[0m ——————————"
				echo -e "	端口: \033[41;37m ${user_port} \033[0m"
				echo -e "	密码: \033[41;37m ${user_password} \033[0m"
				echo -e "${ss_link}"
				echo -e "${ssr_link}"
			done
		fi
		
		echo -e "\033[42;37m 提示： \033[0m"
		echo -e "浏览器中，打开二维码链接，就可以看到二维码图片。"
		echo -e "协议和混淆后面的[ _compatible ]，指的是兼容原版Shadowsocks协议/混淆。"
		echo
		echo -e ${ssr_status}
		echo
		echo "############################################################"
	fi
	
}
debian_apt(){
	apt-get update
	apt-get install -y python-pip python-m2crypto curl unzip vim git gcc build-essential make
}
centos_yum(){
	yum update
	yum install -y python-pip python-m2crypto curl unzip vim git gcc make
}
#安装ShadowsocksR
installSSR(){
	[ -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 发现已安装ShadowsocksR，如果需要继续安装，请先卸载 !" && exit 1
	setUser
	check_sys
	# 系统判断
	if [[ ${release} = "debian" ]]; then
		debian_apt
	elif [[ ${release} = "ubuntu" ]]; then
		debian_apt
	elif [[ ${release} = "centos" ]]; then
		centos_yum
	else
		echo -e "\033[41;37m [错误] \033[0m 本脚本不支持当前系统 !" && exit 1
	fi
	#修改DNS为8.8.8.8
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	
	wget --no-check-certificate -N 'https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz'
	tar -xzf jq-1.5.tar.gz && cd jq-1.5
	./configure && make && make install
	ldconfig
	cd ..
	rm -rf jq-1.5.tar.gz
	rm -rf jq-1.5
	
	cd /etc
	#git config --global http.sslVerify false
	env GIT_SSL_NO_VERIFY=true git clone -b manyuser https://github.com/shadowsocksr/shadowsocksr.git
	[ ! -e ${config_file} ] && echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 下载失败 !" && exit 1
	cp ${config_file} ${config_user_file}
	#修改配置文件的密码 端口 加密方式
	cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": ${ssport},
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "${sspwd}",
    "timeout": 120,
    "udp_timeout": 60,
    "method": "${ssmethod}",
    "protocol": "${ssprotocol}",
    "protocol_param": "${ssprotocol_param}",
    "obfs": "${ssobfs}",
    "obfs_param": "",
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF

	#添加新端口的规则
	iptables_add
	#Debian 添加开机启动
	chmod +x /etc/rc.local
	sed -i '$d' /etc/rc.local
	echo -e "python ${server_file} -d start" >> /etc/rc.local
	echo -e "exit 0" >> /etc/rc.local
	#启动SSR服务端，并判断是否启动成功
	cd ${server_file}
	nohup python server.py a >> ssserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [ ! -z "${PID}" ]; then
		viewUser
		echo
		echo -e "ShadowsocksR 安装完成 !"
		echo -e "https://doub.io/ss-jc42/"
		echo
		echo "############################################################"
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR服务端启动失败 !"
	fi
}
installLibsodium(){
	#[ -e $Libsodiumr_file ] && echo -e "\033[41;37m [错误] \033[0m 发现已安装 Libsodium，如果需要继续安装，请先卸载 !" && exit 1
	# 系统判断
	check_sys
	if [[ ${release}  != "debian" ]]; then
		if [[ ${release}  != "ubuntu" ]]; then
			if [[ ${release}  != "centos" ]]; then
				echo -e "\033[41;37m [错误] \033[0m 本脚本不支持当前系统 !" && exit 1
			fi
		fi
	fi
	if [[ ${release} != "centos" ]]; then
		apt-get update && apt-get install -y gcc build-essential make
	else
		yum update && yum install -y gcc make
	fi
	cd /root
	wget  --no-check-certificate -N -O libsodium.tar.gz https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz
	tar -xzf libsodium.tar.gz && mv libsodium-${Libsodiumr_ver} libsodium && cd libsodium
	./configure && make -j2 && make install
	ldconfig
	cd ..
	rm -rf libsodium.tar.gz
	rm -rf libsodium
	echo "——————————————————————————————"
	echo
	echo -e "Libsodium 安装完成 !"
	echo -e "https://www.doub.io/ss-jc42/"
	echo
	echo "——————————————————————————————"
}
iptables_add(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssport} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssport} -j ACCEPT
}
iptables_del(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
iptables_set(){
	#删除旧端口的防火墙规则，添加新端口的规则
	iptables_del
	iptables_add
}
#修改单端口用户配置
modifyUser(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	getUser
	setUser
	#修改配置文件的密码 端口 加密方式
	sed -i 's/"server_port": '$(echo ${port})'/"server_port": '$(echo ${ssport})'/g' ${config_user_file}
	sed -i 's/"password": "'$(echo ${password})'"/"password": "'$(echo ${sspwd})'"/g' ${config_user_file}
	sed -i 's/"method": "'$(echo ${method})'"/"method": "'$(echo ${ssmethod})'"/g' ${config_user_file}
	sed -i 's/"obfs": "'$(echo ${obfs})'"/"obfs": "'$(echo ${ssobfs})'"/g' ${config_user_file}
	sed -i 's/"protocol": "'$(echo ${protocol})'"/"protocol": "'$(echo ${ssprotocol})'"/g' ${config_user_file}
	sed -i 's/"protocol_param": "'$(echo ${protocol_param})'"/"protocol_param": "'$(echo ${ssprotocol_param})'"/g' ${config_user_file}
	iptables_set
	python ${server_file} -d restart
	viewUser
}
#手动修改用户配置
manuallyModifyUser(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	port=`jq '.server_port' ${config_user_file}`
	vi $config_user_file
	ssport=`jq '.server_port' ${config_user_file}`
	iptables_set
	python ${server_file} -d restart
	viewUser
}
#卸载ShadowsocksR
UninstallSSR(){
	[ ! -e $config_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	echo "确定要卸载ShadowsocksR ? (y/N)"
	echo
	read -p "(默认: n):" unyn
	[ -z ${unyn} ] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		#停止ShadowsocksR服务端并删除防火墙规则，删除Shadowsocks文件夹。
		python ${server_file} -d stop
		now_mode=`jq '.port_password' ${config_user_file}`
		if [ "${now_mode}" = "null" ]; then
			port=`jq '.server_port' ${config_user_file}`
			iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		else
			user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				iptables_del
			done
		fi
		#取消开机启动
		sed -i '/python \/etc\/shadowsocksr\/shadowsocks\/server.py -d start/d' /etc/rc.local
		check_sys
		# 系统判断
		rm -rf ${ssr_file} && rm -rf ${Libsodiumr_file} && rm -rf ${Libsodiumr_file}.tar.gz
		echo
		echo "	ShadowsocksR 卸载完成 !"
		echo
	else
		echo
		echo "	卸载已取消..."
		echo
	fi
}
# 更新ShadowsocksR
UpdateSSR(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	cd ${ssr_file}
	git pull
	python ${server_file} -d restart
}
# 切换 单/多端口模式
Port_mode_switching(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	now_mode=`jq '.port_password' ${config_user_file}`
	if [ "${now_mode}" = "null" ]; then
		echo
		echo -e "	当前ShadowsocksR模式：\033[42;37m 单端口 \033[0m"
		echo
		echo -e "确定要切换模式为 \033[42;37m 多端口 \033[0m ? (y/N)"
		echo
		read -p "(默认: n):" mode_yn
		[ -z ${mode_yn} ] && mode_yn="n"
		if [[ ${mode_yn} == [Yy] ]]; then
			port=`jq '.server_port' ${config_user_file}`
			setUser
			iptables_set
			cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "port_password":{
        "${ssport}":"${sspwd}"
    },
    "timeout": 120,
    "udp_timeout": 60,
    "method": "${ssmethod}",
    "protocol": "${ssprotocol}",
    "protocol_param": "${ssprotocol_param}",
    "obfs": "${ssobfs}",
    "obfs_param": "",
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
			RestartSSR
		else
			echo
			echo "	已取消..."
			echo
		fi
	else
		echo
		echo -e "	当前ShadowsocksR模式：\033[42;37m 多端口 \033[0m"
		echo
		echo -e "确定要切换模式为 \033[42;37m 单端口 \033[0m ? (y/N)"
		echo
		read -p "(默认: n):" mode_yn
		[ -z ${mode_yn} ] && mode_yn="n"
		if [[ ${mode_yn} == [Yy] ]]; then
			user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				iptables_del
			done
			setUser
			iptables_add
		cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": ${ssport},
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "${sspwd}",
    "timeout": 120,
    "udp_timeout": 60,
    "method": "${ssmethod}",
    "protocol": "${ssprotocol}",
    "protocol_param": "${ssprotocol_param}",
    "obfs": "${ssobfs}",
    "obfs_param": "",
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}
EOF
			RestartSSR
		else
			echo
			echo "	已取消..."
			echo
		fi
	fi
}
# 设置多端口用户的端口和密码
set_multi_port_user(){
	#设置端口
	while true
	do
	echo -e "请输入ShadowsocksR账号的 端口 [1-65535]:"
	read -p "(默认端口: 2333):" ssport
	[ -z "$ssport" ] && ssport="2333"
	expr ${ssport} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${ssport} -ge 1 ] && [ ${ssport} -le 65535 ]; then
			echo
			echo "——————————————————————————————"
			echo -e "	端口 : \033[41;37m ${ssport} \033[0m"
			echo "——————————————————————————————"
			echo
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
	#设置密码
	echo "请输入ShadowsocksR账号的 密码:"
	read -p "(默认密码: doub.io):" sspwd
	[ -z "${sspwd}" ] && sspwd="doub.io"
	echo
	echo "——————————————————————————————"
	echo -e "	密码 : \033[41;37m ${sspwd} \033[0m"
	echo "——————————————————————————————"
	echo
}
# 设置多端口用户的协议和混淆
set_multi_port_user_others(){
	#设置加密方式
	echo "请输入数字 来选择ShadowsocksR账号的 加密方式:"
	echo "1. rc4-md5"
	echo "2. aes-256-ctr"
	echo "3. aes-256-cfb"
	echo "4. aes-256-cfb8"
	echo "5. camellia-256-cfb"
	echo "6. chacha20"
	echo "7. chacha20-ietf"
	echo
	read -p "(默认加密方式: 3. aes-256-cfb):" ssmethod
	[ -z "${ssmethod}" ] && ssmethod="3"
	if [ ${ssmethod} == "1" ]; then
		ssmethod="rc4-md5"
	elif [ ${ssmethod} == "2" ]; then
		ssmethod="aes-256-ctr"
	elif [ ${ssmethod} == "3" ]; then
		ssmethod="aes-256-cfb"
	elif [ ${ssmethod} == "4" ]; then
		ssmethod="aes-256-cfb8"
	elif [ ${ssmethod} == "5" ]; then
		ssmethod="camellia-256-cfb"
	elif [ ${ssmethod} == "6" ]; then
		ssmethod="chacha20"
	elif [ ${ssmethod} == "7" ]; then
		ssmethod="chacha20-ietf"
	else
		ssmethod="aes-256-cfb"
	fi
	echo
	echo "——————————————————————————————"
	echo -e "	加密方式 : \033[41;37m ${ssmethod} \033[0m"
	echo "——————————————————————————————"
	echo
	#设置协议
	echo "请输入数字 来选择ShadowsocksR账号的 协议( auth_aes128_* 以后的协议不再支持 兼容原版 ):"
	echo "1. origin"
	echo "2. verify_sha1"
	echo "3. auth_sha1_v2"
	echo "4. auth_sha1_v4"
	echo "5. auth_aes128_md5"
	echo "6. auth_aes128_sha1"
	echo
	read -p "(默认协议: 5. auth_aes128_md5):" ssprotocol
	[ -z "${ssprotocol}" ] && ssprotocol="5"
	if [ ${ssprotocol} == "1" ]; then
		ssprotocol="origin"
	elif [ ${ssprotocol} == "2" ]; then
		ssprotocol="verify_sha1"
	elif [ ${ssprotocol} == "3" ]; then
		ssprotocol="auth_sha1_v2"
	elif [ ${ssprotocol} == "4" ]; then
		ssprotocol="auth_sha1_v4"
	elif [ ${ssprotocol} == "5" ]; then
		ssprotocol="auth_aes128_md5"
	elif [ ${ssprotocol} == "6" ]; then
		ssprotocol="auth_aes128_sha1"
	else
		ssprotocol="auth_aes128_md5"
	fi
	echo
	echo "——————————————————————————————"
	echo -e "	协议 : \033[41;37m ${ssprotocol} \033[0m"
	echo "——————————————————————————————"
	echo
	#设置混淆
	echo "请输入数字 来选择ShadowsocksR账号的 混淆:"
	echo "1. plain"
	echo "2. http_simple"
	echo "3. http_post"
	echo "4. random_head"
	echo "5. tls1.2_ticket_auth"
	echo
	read -p "(默认混淆: 5. tls1.2_ticket_auth):" ssobfs
	[ -z "${ssobfs}" ] && ssobfs="5"
	if [ ${ssobfs} == "1" ]; then
		ssobfs="plain"
	elif [ ${ssobfs} == "2" ]; then
		ssobfs="http_simple"
	elif [ ${ssobfs} == "3" ]; then
		ssobfs="http_post"
	elif [ ${ssobfs} == "4" ]; then
		ssobfs="random_head"
	elif [ ${ssobfs} == "5" ]; then
		ssobfs="tls1.2_ticket_auth"
	else
		ssobfs="tls1.2_ticket_auth"
	fi
	echo
	echo "——————————————————————————————"
	echo -e "	混淆 : \033[41;37m ${ssobfs} \033[0m"
	echo "——————————————————————————————"
	echo
	#询问是否设置 混淆 兼容原版
	if [ ${ssprotocol} != "origin" ]; then
		if [ ${ssobfs} != "plain" ]; then
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				read -p "是否设置 协议/混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
				[ -z "${yn1}" ] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible" && ssprotocol=${ssprotocol}"_compatible"
			else
				read -p "是否设置 混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
				[ -z "${yn1}" ] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
			fi
		else
			if [[ ${ssprotocol} == "verify_sha1" ]] || [[ ${ssprotocol} == "auth_sha1_v2" ]]  || [[ ${ssprotocol} == "auth_sha1_v4" ]]; then
				read -p "是否设置 协议 兼容原版 ( _compatible )? [Y/n] :" yn1
				[ -z "${yn1}" ] && yn1="y"
				[[ $yn1 == [Yy] ]] && ssprotocol=${ssprotocol}"_compatible"
			fi
		fi
	else
		if [ ${ssobfs} != "plain" ]; then
			read -p "是否设置 混淆 兼容原版 ( _compatible )? [Y/n] :" yn1
			[ -z "${yn1}" ] && yn1="y"
			[[ $yn1 == [Yy] ]] && ssobfs=${ssobfs}"_compatible"
		fi
	fi
	if [ ${ssprotocol} != "origin" ]; then
		while true
		do
		echo
		echo -e "请输入 ShadowsocksR账号欲限制的链接IP数(\033[42;37m auth_* 系列协议 不兼容原版才有效 \033[0m)"
		read -p "(回车 默认无限):" ssprotocol_param
		[ -z "$ssprotocol_param" ] && ssprotocol_param=0 && break
		expr ${ssprotocol_param} + 0 &>/dev/null
		if [ $? -eq 0 ]; then
			if [ ${ssprotocol_param} -ge 1 ] && [ ${ssprotocol_param} -le 99999 ]; then
				echo
				echo "——————————————————————————————"
				echo -e "	链接设备数 : \033[41;37m ${ssprotocol_param} \033[0m"
				echo "——————————————————————————————"
				echo
				break
			else
				echo "输入错误，请输入正确的数字 !"
			fi
		else
			echo "输入错误，请输入正确的数字 !"
		fi
		done
	fi
	[ "${ssprotocol_param}" = 0 ] && ssprotocol_param=""
}
List_multi_port_user(){
	user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[[ ${socat_total} = "0" ]] && echo -e "\033[41;37m [错误] \033[0m 没有发现 多端口用户，请检查 !" && exit 1
	user_list_all=""
	user_id=0
	check_sys
	if [[ ${release} = "centos" ]]; then
		for((integer = 1; integer <= ${user_total}; integer++))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 用户密码: "${user_password}"\n"
		done
	else
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_password=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $2}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 用户密码: "${user_password}"\n"
		done
	fi
	echo
	echo -e "当前有 \033[42;37m "${user_total}" \033[0m 个用户配置。"
	echo -e ${user_list_all}
}
# 添加 多端口用户配置
Add_multi_port_user(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	now_mode=`jq '.port_password' ${config_user_file}`
	[ "${now_mode}" = "null" ] && echo -e "\033[41;37m [错误] \033[0m 当前ShadowsocksR模式为 单用户，请检查 !" && exit 1
	set_multi_port_user
	sed -i "7 i \"        \"${ssport}\":\"${sspwd}\"," ${config_user_file}
	sed -i "7s/^\"//" ${config_user_file}
	iptables_add
	RestartSSR
	echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 多端口用户 \033[42;37m [端口: ${ssport} , 密码: ${sspwd}] \033[0m 已添加!"
}
# 修改 多端口用户配置
Modify_multi_port_user(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	now_mode=`jq '.port_password' ${config_user_file}`
	[ "${now_mode}" = "null" ] && echo -e "\033[41;37m [错误] \033[0m 当前ShadowsocksR模式为 单用户，请检查 !" && exit 1
	echo "请输入数字 来选择你要修改的类型 :"
	echo "1. 修改 用户端口/密码"
	echo "2. 修改 全局协议/混淆"
	read -p "(默认回车取消):" modify_type
	[ -z "${modify_type}" ] && exit 1
	if [ ${modify_type} == "1" ]; then
		List_multi_port_user
		while true
		do
		echo -e "请选择并输入 你要修改的用户前面的数字 :"
		read -p "(默认回车取消):" del_user_num
		[ -z "${del_user_num}" ] && exit 1
		expr ${del_user_num} + 0 &>/dev/null
		if [ $? -eq 0 ]; then
			if [ ${del_user_num} -ge 1 ] && [ ${del_user_num} -le ${user_total} ]; then
				set_multi_port_user
				del_user_num_3=$[ $del_user_num + 6]
				port=`sed -n "${del_user_num_3}p" ${config_user_file} | awk -F ":" '{print $1}' | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				password=`sed -n "${del_user_num_3}p" ${config_user_file} | awk -F ":" '{print $2}' | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
				sed -i 's/"'$(echo ${port})'":"'$(echo ${password})'"/"'$(echo ${ssport})'":"'$(echo ${sspwd})'"/g' ${config_user_file}
				iptables_set
				RestartSSR
				echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 多端口用户 \033[42;37m ${del_user_num} \033[0m 已修改!"
				break
			else
				echo "输入错误，请输入正确的数字 !"
			fi
		else
			echo "输入错误，请输入正确的数字 !"
		fi
		done	
	elif [ ${modify_type} == "2" ]; then
		set_multi_port_user_others
		getUser
		sed -i 's/"method": "'$(echo ${method})'"/"method": "'$(echo ${ssmethod})'"/g' ${config_user_file}
		sed -i 's/"obfs": "'$(echo ${obfs})'"/"obfs": "'$(echo ${ssobfs})'"/g' ${config_user_file}
		sed -i 's/"protocol": "'$(echo ${protocol})'"/"protocol": "'$(echo ${ssprotocol})'"/g' ${config_user_file}
		sed -i 's/"protocol_param": "'$(echo ${protocol_param})'"/"protocol_param": "'$(echo ${ssprotocol_param})'"/g' ${config_user_file}
		RestartSSR
		echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 加密方式/协议/混淆 已修改!"
	fi
}
# 删除 多端口用户配置
Del_multi_port_user(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	now_mode=`jq '.port_password' ${config_user_file}`
	[ "${now_mode}" = "null" ] && echo -e "\033[41;37m [错误] \033[0m 当前ShadowsocksR模式为 单用户，请检查 !" && exit 1
	List_multi_port_user
	user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
	[ "${user_total}" -le "1" ] && echo -e "\033[41;37m [错误] \033[0m 当前仅剩下一个多端口用户，无法删除 !" && exit 1
	while true
	do
	echo -e "请选择并输入 你要删除的用户前面的数字 :"
	read -p "(默认回车取消):" del_user_num
	[ -z "${del_user_num}" ] && exit 1
	expr ${del_user_num} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${del_user_num} -ge 1 ] && [ ${del_user_num} -le ${user_total} ]; then
			del_user_num_4=$[ $del_user_num + 6]
			port=`sed -n "${del_user_num_4}p" ${config_user_file} | awk -F ":" '{print $1}' | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			iptables_del
			del_user_num_1=$[ $del_user_num + 6 ]
			sed -i "${del_user_num_1}d" ${config_user_file}
			if [ ${del_user_num} = ${user_total} ]; then
				del_user_num_1=$[ $del_user_num_1 - 1 ]
				sed -i "${del_user_num_1}s/,$//g" ${config_user_file}
			fi
			RestartSSR
			echo -e "\033[42;37m [信息] \033[0m ShadowsocksR 多端口用户 \033[42;37m ${del_user_num} \033[0m 已删除!"
			break
		else
			echo "输入错误，请输入正确的数字 !"
		fi
	else
		echo "输入错误，请输入正确的数字 !"
	fi
	done
}
# 显示用户连接信息
View_user_connection_info(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	check_sys
	if [[ ${release} = "debian" ]]; then
		debian_View_user_connection_info
	elif [[ ${release} = "ubuntu" ]]; then
		debian_View_user_connection_info
	elif [[ ${release} = "centos" ]]; then
		centos_View_user_connection_info
	fi
}
debian_View_user_connection_info(){
	now_mode=`jq '.port_password' ${config_user_file}`
	if [ "${now_mode}" = "null" ]; then
		now_mode="单端口模式" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_port=`jq '.server_port' ${config_user_file}`
		user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
		user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_list_all="1. 用户端口: "${user_port}" 链接端口的IP总数: "${user_IP_total}" 链接端口的IP: "${user_IP}"\n"
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前有 \033[42;37m "${user_IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	else
		now_mode="多端口模式" && user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
		user_list_all=""
		user_id=0
		for((integer = ${user_total}; integer >= 1; integer--))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
			user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep "${user_port}" |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 链接端口的IP总数: "${user_IP_total}" 链接端口的IP: "${user_IP}"\n"
		done
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前有 \033[42;37m "${user_total}" \033[0m 个用户配置，当前有 \033[42;37m "${user_IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	fi
}
centos_View_user_connection_info(){
	now_mode=`jq '.port_password' ${config_user_file}`
	if [ "${now_mode}" = "null" ]; then
		now_mode="单端口模式" && user_total="1"
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $4}' |sort -u |wc -l`
		user_port=`jq '.server_port' ${config_user_file}`
		user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
		user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
		user_list_all="1. 用户端口: "${user_port}" 链接端口的IP总数: "${user_IP_total}" 链接端口的IP: "${user_IP}"\n"
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前有 \033[42;37m "${user_IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	else
		now_mode="多端口模式" && user_total=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | wc -l`
		IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $4}' |sort -u |wc -l`
		user_list_all=""
		user_id=0
		for((integer = 1; integer <= ${user_total}; integer++))
		do
			user_port=`jq '.port_password' ${config_user_file} | sed '$d' | sed "1d" | awk -F ":" '{print $1}' | sed -n "${integer}p" | perl -e 'while($_=<>){ /\"(.*)\"/; print $1;}'`
			user_IP=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
			user_IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep "${user_port}" | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
			user_id=$[$user_id+1]
			user_list_all=${user_list_all}${user_id}". 用户端口: "${user_port}" 链接端口的IP总数: "${user_IP_total}" 链接端口的IP: "${user_IP}"\n"
		done
		echo -e "当前是 \033[42;37m "${now_mode}" \033[0m ，当前有 \033[42;37m "${user_total}" \033[0m 个用户配置，当前有 \033[42;37m "${user_IP_total}" \033[0m 个IP正在链接。"
		echo -e ${user_list_all}
	fi
}

#启动ShadowsocksR
StartSSR(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[ ! -z ${PID} ] && echo -e "\033[41;37m [错误] \033[0m 发现ShadowsocksR正在运行，请检查 !" && exit 1
	cd ${server_file}
	nohup python server.py a >> ssserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [ ! -z "${PID}" ]; then
		viewUser
		echo "——————————————————————————————"
		echo
		echo -e "	ShadowsocksR 已启动 !"
		echo
		echo "——————————————————————————————"
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR启动失败 !"
	fi
}
#停止ShadowsocksR
StopSSR(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[ -z $PID ] && echo -e "\033[41;37m [错误] \033[0m 发现ShadowsocksR没有运行，请检查 !" && exit 1
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [ -z "${PID}" ]; then
		echo "——————————————————————————————"
		echo
		echo -e "	ShadowsocksR 已停止 !"
		echo
		echo "——————————————————————————————"
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 停止失败 !"
	fi
}
#重启ShadowsocksR
RestartSSR(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	[ ! -z "${PID}" ] && kill -9 ${PID}
	cd ${server_file}
	nohup python server.py a >> ssserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [ ! -z "${PID}" ]; then
		viewUser
		echo "——————————————————————————————"
		echo
		echo -e "	ShadowsocksR 已启动 !"
		echo
		echo "——————————————————————————————"
	else
		echo -e "\033[41;37m [错误] \033[0m ShadowsocksR 启动失败 !"
	fi
}
#查看 ShadowsocksR 日志
TailSSR(){
	[ ! -f $server_file"/ssserver.log" ] && echo -e "\033[41;37m [错误] \033[0m 没有发现ShadowsocksR日志文件，请检查 !" && exit 1
	echo
	echo -e "使用 \033[41;37m Ctrl+C \033[0m 键退出查看日志 !"
	echo
	cd ${server_file}
	tail -f ssserver.log
}
#查看 ShadowsocksR 状态
StatusSSR(){
	[ ! -e $config_user_file ] && echo -e "\033[41;37m [错误] \033[0m 没有发现安装ShadowsocksR，请检查 !" && exit 1
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [ -z "${PID}" ]; then
		echo "——————————————————————————————"
		echo
		echo -e "	ShadowsocksR 没有运行!"
		echo
		echo "——————————————————————————————"
	else
		echo "——————————————————————————————"
		echo
		echo -e "	ShadowsocksR 正在运行(PID: ${PID}) !"
		echo
		echo "——————————————————————————————"
	fi
}
#安装锐速
installServerSpeeder(){
	[ -e "/serverspeeder" ] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 已安装 !" && exit 1
	cd /root
	#借用91yun.rog的开心版锐速
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder-all.sh
	bash serverspeeder-all.sh
	#Debian 添加开机启动
	chmod +x /etc/rc.local
	sed -i '$d' /etc/rc.local
	echo -e "/serverspeeder/bin/serverSpeeder.sh start" >> /etc/rc.local
	echo -e "exit 0" >> /etc/rc.local
}
#查看锐速状态
StatusServerSpeeder(){
	[ ! -e "/serverspeeder" ] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	/serverspeeder/bin/serverSpeeder.sh status
}
#停止锐速
StopServerSpeeder(){
	[ ! -e "/serverspeeder" ] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	/serverspeeder/bin/serverSpeeder.sh stop
}
#重启锐速
RestartServerSpeeder(){
	[ ! -e "/serverspeeder" ] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	/serverspeeder/bin/serverSpeeder.sh restart
	#/serverspeeder/bin/serverSpeeder.sh status
}
#卸载锐速
UninstallServerSpeeder(){
	[ ! -e "/serverspeeder" ] && echo -e "\033[41;37m [错误] \033[0m 锐速(ServerSpeeder) 没有安装，请检查 !" && exit 1
	
	echo "确定要卸载 锐速(ServerSpeeder) ? (y/N)"
	echo
	read -p "(默认: n):" un1yn
	[ -z ${un1yn} ] && un1yn="n"
	if [[ ${un1yn} == [Yy] ]]; then
		rm -rf /root/serverspeeder-all.sh
		rm -rf /root/91yunserverspeeder
		rm -rf /root/91yunserverspeeder.tar.gz
		sed -i '/\/serverspeeder\/bin\/serverSpeeder.sh start/d' /etc/rc.local
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		echo
		echo "锐速(ServerSpeeder) 卸载完成 !"
		echo
	else
		echo
		echo "卸载已取消..."
		echo
	fi
}
BanBTPTSPAM(){
	wget -4qO- softs.pw/Bash/Get_Out_Spam.sh | bash
}

#菜单判断
echo "请输入一个数字来选择对应的选项。"
echo
echo -e "\033[42;37m  1. \033[0m 安装 ShadowsocksR"
echo -e "\033[42;37m  2. \033[0m 安装 libsodium(chacha20)"
echo -e "\033[42;37m  3. \033[0m 显示 单/多端口 账号信息"
echo -e "\033[42;37m  4. \033[0m 显示 单/多端口 连接信息"
echo -e "\033[42;37m  5. \033[0m 修改 单端口用户配置"
echo -e "\033[42;37m  6. \033[0m 手动 修改  用户配置"
echo -e "\033[42;37m  7. \033[0m 卸载 ShadowsocksR"
echo -e "\033[42;37m  8. \033[0m 更新 ShadowsocksR"
echo "————————————————"
echo -e "\033[42;37m  9. \033[0m 切换 单/多端口 模式"
echo -e "\033[42;37m 10. \033[0m 添加 多端口用户配置"
echo -e "\033[42;37m 11. \033[0m 修改 多端口用户配置"
echo -e "\033[42;37m 12. \033[0m 删除 多端口用户配置"
echo "————————————————"
echo -e "\033[42;37m 13. \033[0m 启动 ShadowsocksR"
echo -e "\033[42;37m 14. \033[0m 停止 ShadowsocksR"
echo -e "\033[42;37m 15. \033[0m 重启 ShadowsocksR"
echo -e "\033[42;37m 16. \033[0m 查看 ShadowsocksR 状态"
echo -e "\033[42;37m 17. \033[0m 查看 ShadowsocksR 日志"
echo "————————————————"
echo -e "\033[42;37m 18. \033[0m 安装 锐速(ServerSpeeder)"
echo -e "\033[42;37m 19. \033[0m 停止 锐速(ServerSpeeder)"
echo -e "\033[42;37m 20. \033[0m 重启 锐速(ServerSpeeder)"
echo -e "\033[42;37m 21. \033[0m 查看 锐速(ServerSpeeder) 状态"
echo -e "\033[42;37m 22. \033[0m 卸载 锐速(ServerSpeeder)"
echo "————————————————"
echo -e "\033[42;37m 23. \033[0m 封禁 BT/PT/垃圾邮件(SPAM)"
echo "————————————————"
echo -e "\033[42;37m 当前状态： \033[0m"
if [ -e $config_user_file ]; then
	echo -e " ShadowsocksR服务端 \033[42;37m 已安装 \033[0m"
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
	if [ ! -z "${PID}" ]; then
		echo -e " ShadowsocksR服务端 \033[42;37m 已启动 \033[0m"
	else
		echo -e " ShadowsocksR服务端 \033[41;37m 未启动 \033[0m"
	fi
else
	echo -e " ShadowsocksR服务端 \033[41;37m 未安装 \033[0m"
	echo -e " ShadowsocksR服务端 \033[41;37m 未启动 \033[0m"
fi
echo
read -p "(请输入数字):" num

case "$num" in
	1)
	installSSR
	;;
	2)
	installLibsodium
	;;
	3)
	viewUser
	;;
	4)
	View_user_connection_info
	;;
	5)
	modifyUser
	;;
	6)
	manuallyModifyUser
	;;
	7)
	UninstallSSR
	;;
	8)
	UpdateSSR
	;;
	9)
	Port_mode_switching
	;;
	10)
	Add_multi_port_user
	;;
	11)
	Modify_multi_port_user
	;;
	12)
	Del_multi_port_user
	;;
	13)
	StartSSR
	;;
	14)
	StopSSR
	;;
	15)
	RestartSSR
	;;
	16)
	StatusSSR
	;;
	17)
	TailSSR
	;;
	18)
	installServerSpeeder
	;;
	19)
	StopServerSpeeder
	;;
	20)
	RestartServerSpeeder
	;;
	21)
	StatusServerSpeeder
	;;
	22)
	UninstallServerSpeeder
	;;
	23)
	BanBTPTSPAM
	;;
	*)
	echo '请选择并输入 1-23 的数字。'
	;;
esac