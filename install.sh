#!/bin/bash
install_path=`pwd`
args_len=$#

if [ $args_len == 0 ];then
	echo "The lack of necessary parameters"
	echo "USAGE: ./install.sh controller password token listen_ip
	options:
		controller	This is controller node can access url or IP
		password	This is mysql password and keystone,glance,nova,neutron user password
		token		This is keystone identity service admin_token
		listen_ip	This ip is for mysql bind_address ip"
	exit
fi

if [ $args_len != 7 ];then
	echo "args length is wrong"
	exit
fi

#接受参数赋值定义
#controller node ip 
controller=$1		

#mysql bind address
listen_ip=$2

#token
token=$3

#mysql password
mysql_pass=$4

#service password
service_pass=$5

#user password
user_pass=$6

#user email
user_email=$7

touch /tmp/openstack.log
echo $controller >> /tmp/openstack.log
echo $listen_ip >> /tmp/openstack.log
echo $token >> /tmp/openstack.log
echo $mysql_pass >> /tmp/openstack.log
echo $service_pass >> /tmp/openstack.log
echo $user_pass >> /tmp/openstack.log
echo $user_email >> /tmp/openstack.log


#replace environment variable
sed -i "s/CONTROLLER/$1/" $install_path/tmp_env
sed -i "s/ADMINTOKEN/$3/" $install_path/tmp_env


sed -i "s/CONTROLLER/$1/" $install_path/admin_creds

#安装epel、openstack-icehouse源
/bin/bash $install_path/base.sh

#安装mysql
/bin/bash $install_path/librpm.sh  $listen_ip $mysql_pass

#安装keystone service
/bin/bash $install_path/keystone.sh $controller  $listen_ip $token $mysql_pass $service_pass $user_pass $user_email

#安装glance service
/bin/bash $install_path/glance.sh $controller  $listen_ip $token $mysql_pass $service_pass $user_pass $user_email

#安装nova service 
/bin/bash $install_path/nova.sh $controller  $listen_ip $token $mysql_pass $service_pass $user_pass $user_email

#安装neutron service
/bin/bash $install_path/neutron.sh $controller  $listen_ip $token $mysql_pass $service_pass $user_pass $user_email

#安装dashboard service
/bin/bash $install_path/dashboard.sh $controller  $listen_ip $token $mysql_pass $service_pass $user_pass $user_email
