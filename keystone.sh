#!/bin/bash
base_path=`pwd`
#admin_token='828b53429ff1054a04a4'

if [ $# == 0 ];then
	echo "please input correct args or agrs_len"
	exit
fi

if [ $# != 7 ];then
	echo "args length is wrong"
	exit
fi

#参数赋值定义
controller=$1
listen_ip=$2
admin_token=$3
mysql_pass=$4
service_pass=$5
user_pass=$6
user_email=$7
db_port=3306

#安装keystone服务
yum install -y openstack-keystone python-keystoneclient

#创建keystone数据库
mysql -u root -p$mysql_pass -e "CREATE DATABASE keystone"
mysql -u root -p$mysql_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${mysql_pass}'"
mysql -u root -p$mysql_pass -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${mysql_pass}'"
mysql -u root -p$mysql_pass -e "FLUSH PRIVILEGES"

#add tmp environment
source $base_path/tmp_env

#modify /etc/keystone.conf
mv /etc/keystone/keystone.conf /etc/keystone/keystone.conf.backup
cp -f $base_path/conf/keystone/keystone.conf /etc/keystone/

sed -i "s/ADMINTOKEN/${admin_token}/" /etc/keystone/keystone.conf
sed -i "s/DBPASS/${mysql_pass}/" /etc/keystone/keystone.conf
sed -i "s/DBIP/${listen_ip}/" /etc/keystone/keystone.conf
sed -i "s/DBPORT/${db_port}/" /etc/keystone/keystone.conf

chown -R root.keystone /etc/keystone/keystone.conf
service openstack-keystone start

chown -R keystone.keystone /var/log/keystone/keystone.log
keystone-manage db_sync

#Create an administrative user
keystone user-create --name=admin --pass=$user_pass --email=$user_email
keystone role-create --name=admin
keystone tenant-create --name=admin --description="Admin Tenant"
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin

#Create a normal user
keystone user-create --name=demo --pass=$user_pass --email=$user_email
keystone tenant-create --name=demo --description="Demo Tenant"
keystone user-role-add --user=demo --role=_member_ --tenant=demo

#Create a service tenant
keystone tenant-create --name=service --description="Service Tenant"

#Define services and API endpoints:
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"

keystone endpoint-create --service-id=$(keystone service-list | awk '/ identity / {print $2}') --publicurl=http://$controller:5000/v2.0 --internalurl=http://$controller:5000/v2.0 --adminurl=http://$controller:35357/v2.0

#Create the signing keys and certificates and restrict access to the generated data:
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl

#clear the values in the OS_SERVICE_TOKEN and OS_SERVICE_ENDPOINT environment variables
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT

# Load credential admin file
source $base_path/admin_creds

keystone user-list
keystone user-role-list --user admin --tenant admin	
