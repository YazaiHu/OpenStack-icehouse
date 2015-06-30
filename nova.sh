#!/bin/bash
base_path=`pwd`

source $base_path/admin_creds

#安装nova服务
yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient


if [ $# == 0 ];then
	echo "args lengths is wrong"
	exit
fi

if [ $# != 7 ];then
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


mysql -uroot -p$mysql_pass -e "CREATE DATABASE nova"
mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${mysql_pass}'"
mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${mysql_pass}'"
mysql -uroot -p$mysql_pass -e "FLUSH PRIVILEGES"

#创建nova用户
keystone user-create --name=nova --pass=$user_pass --email=$user_email
keystone user-role-add --user=nova --tenant=service --role=admin

keystone service-create --name=nova --type=compute --description="OpenStack Compute" 
keystone endpoint-create --service-id=$(keystone service-list | awk '/ compute / {print $2}') --publicurl=http://$controller:8774/v2/%\(tenant_id\)s --internalurl=http://$controller:8774/v2/%\(tenant_id\)s --adminurl=http://$controller:8774/v2/%\(tenant_id\)s


mv /etc/nova/nova.conf /etc/nova/nova.conf.backup
cp $base_path/conf/nova/nova.conf /etc/nova/nova.conf
chown -R root.nova /etc/nova/nova.conf

sed -i "s/CONTROLLER/${controller}/" /etc/nova/nova.conf
sed -i "s/USERPASS/${user_pass}/" /etc/nova/nova.conf
sed -i "s/DBPORT/${db_port}/" /etc/nova/nova.conf
sed -i "s/DBIP/${listen_ip}/" /etc/nova/nova.conf
sed -i "s/DBPASS/${mysql_pass}/" /etc/nova/nova.conf

#同步数据库
nova-manage db sync

service openstack-nova-api start
service openstack-nova-cert start
service openstack-nova-consoleauth start
service openstack-nova-scheduler start
service openstack-nova-conductor start
service openstack-nova-novncproxy start

#check node is running
nova-manage service list

nova image-list
