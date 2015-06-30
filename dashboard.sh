#!/bin/bash
base_path=`pwd`

source $base_path/admin_creds

#安装dashboard服务
yum install -y  httpd memcached python-memcached mod_wsgi openstack-dashboard 

if [ $# == 0 ];then
	echo "args length is wrong"
	exit
fi

controller=$1
listen_ip=$2
token=$3
mysql_pass=$4
service_pass=$5
user_pass=$6
user_email=$7
db_port=3306

mv /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/local_settings.backup
cp $base_path/conf/dashboard/local_settings /etc/openstack-dashboard/local_settings
chown -R root.apache /etc/openstack-dashboard/local_settings

sed -i "s/CONTROLLER/${controller}/" /etc/openstack-dashboard/local_settings 

mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.backup
cp $base_path/conf/apache/httpd.conf /etc/httpd/conf/httpd.conf

sed -i "s/CONTROLLER/${controller}/" /etc/httpd/conf/httpd.conf 

setsebool -P httpd_can_network_connect on

service httpd start
service memcached start
chkconfig httpd on
chkconfig memcached on

#web 访问
#http://$controller/dashboard
