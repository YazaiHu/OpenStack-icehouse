#!/bin/bash
base_path=`pwd`

source $base_path/admin_creds

#安装镜像服务glance
yum install -y openstack-glance python-glanceclient 


if [ $# == 0 ];then
	echo "args length is wrong"
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

#创建glance数据库
mysql -uroot -p$mysql_pass -e "CREATE DATABASE glance"
mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${mysql_pass}'"
mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${mysql_pass}'"
mysql -uroot -p$mysql_pass -e "FLUSH PRIVILEGES"

#Configure service user and role:
keystone user-create --name=glance --pass=$user_pass --email=$user_email
keystone user-role-add --user=glance --tenant=service --role=admin

#Register the service and create the endpoint:
keystone service-create --name=glance --type=image --description="OpenStack Image Service"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ image / {print $2}') --publicurl=http://$controller:9292 --internalurl=http://$controller:9292 --adminurl=http://$controller:9292

#替换glance-api.conf配置文件
mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.backup
mv /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.backup
cp $base_path/conf/glance/glance-api.conf /etc/glance/glance-api.conf
cp $base_path/conf/glance/glance-registry.conf /etc/glance/glance-registry.conf


chown -R root.glance /etc/glance/glance-api.conf
chown -R root.glance /etc/glance/glance-registry.conf

sed -i "s/CONTROLLER/${controller}/" /etc/glance/glance-api.conf
sed -i "s/USERPASS/${user_pass}/" /etc/glance/glance-api.conf
sed -i "s/DBIP/${listen_ip}/" /etc/glance/glance-api.conf
sed -i "s/DBPASS/${mysql_pass}/" /etc/glance/glance-api.conf
sed -i "s/DBPORT/${db_port}/" /etc/glance/glance-api.conf

sed -i "s/CONTROLLER/${controller}/" /etc/glance/glance-registry.conf
sed -i "s/USERPASS/${user_pass}/" /etc/glance/glance-registry.conf
sed -i "s/DBPASS/${mysql_pass}/" /etc/glance/glance-registry.conf
sed -i "s/DBIP/${listen_ip}/" /etc/glance/glance-registry.conf
sed -i "s/DBPORT/${db_port}/" /etc/glance/glance-registry.conf

service openstack-glance-api start
service openstack-glance-registry start

#同步数据库
glance-manage db_sync
#执行以上命令会报错，需要安装gmp5以上版本,下载地址https://gmplib.org/#DOWNLOAD

glance image-create --name "cirros-0.3.2-x86_64" --is-public true --container-format bare --disk-format qcow2 --location http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

#列举出当前镜像列表
glance image-list

