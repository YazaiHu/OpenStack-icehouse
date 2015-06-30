#!/bin/bash
base_path=`pwd`

source $base_path/admin_creds

#安装neutron服务
yum install -y openstack-neutron openstack-neutron-ml2 python-neutronclient openstack-neutron-openvswitch 


if [ $# == 0 ];then
	echo "args length is wrong"
	exit
fi

if [ $# != 7 ];then
	echo "args length is wrong"
	exit
fi

mv /etc/sysctl.conf /etc/sysctl.conf.backup
cp $base_path/conf/sysctl.conf /etc/sysctl.conf
sysctl -p

controller=$1
listen_ip=$2
token=$3
mysql_pass=$4
service_pass=$5
user_pass=$6
user_email=$7
db_port=3306
region=regionOne

mysql -uroot -p$mysql_pass -e "CREATE DATABASE neutron"
mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON neutron.* TO neutron@'localhost' IDENTIFIED BY '${mysql_pass}'"
mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON neutron.* TO neutron@'%' IDENTIFIED BY '${mysql_pass}'"
mysql -uroot -p$mysql_pass -e "FLUSH PRIVILEGES"


keystone user-create --name=neutron --pass=$user_pass --email=$user_email
keystone user-role-add --user=neutron --tenant=service --role=admin

keystone service-create --name=neutron --type=network --description="OpenStack Networking"

keystone endpoint-create --service-id=$(keystone service-list | awk '/ network / {print $2}') --publicurl=http://$controller:9696 --internalurl=http://$controller:9696 --adminurl=http://$controller:9696


mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.backup
cp $base_path/conf/neutron/neutron.conf /etc/neutron/neutron.conf
chown -R root.neutron /etc/neutron/neutron.conf

tenant_id=$(keystone tenant-list | awk '/ service / {print $2}')
sed -i "s/CONTROLLER/${controller}/" /etc/neutron/neutron.conf
sed -i "s/TENANTID/${tenant_id}/" /etc/neutron/neutron.conf
sed -i "s/USERPASS/${user_pass}/g" /etc/neutron/neutron.conf
sed -i "s/DBIP/${listen_ip}/" /etc/neutron/neutron.conf
sed -i "s/DBPASS/${mysql_pass}/" /etc/neutron/neutron.conf
sed -i "s/DBPORT/${db_port}/" /etc/neutron/neutron.conf

mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.backup
cp $base_path/conf/neutron/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
chown -R root.neutron /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i "s/CONTROLLER/${controller}/" /etc/neutron/plugins/ml2/ml2_conf.ini

mv /etc/neutron/dhcp_agent.ini	/etc/neutron/dhcp_agent.ini.backup
cp $base_path/conf/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
chown -R root.neutron /etc/neutron/dhcp_agent.ini

cp $base_path/conf/neutron/dnsmasq-neutron.conf /etc/neutron/dnsmasq-neutron.conf


mv /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.backup
cp $base_path/conf/neutron/l3_agent.ini /etc/neutron/l3_agent.ini

mv /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.backup
cp $base_path/conf/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini

sed -i "s/CONTROLLER/${controller}/" /etc/neutron/metadata_agent.ini
sed -i "s/REGION/${region}/" /etc/neutron/metadata_agent.ini
sed -i "s/USERPASS/${user_pass}/" /etc/neutron/metadata_agent.ini


ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade icehouse" neutron

service openstack-nova-api restart
service openstack-nova-scheduler restart
service openstack-nova-conductor restart

# Restart the Networking service:
service neutron-server start

# Start the OVS service and configure it to start when the system boots:
service openvswitch start
# Add the integration and external bridges:

ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex

# Assign the right config file for OVS:
cp /etc/init.d/neutron-openvswitch-agent /etc/init.d/neutron-openvswitch-agent.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /etc/init.d/neutron-openvswitch-agent

# Start the Networking services and configure them to start when the system boots:
service neutron-openvswitch-agent start
service neutron-dhcp-agent start
service neutron-l3-agent start
service neutron-metadata-agent start
