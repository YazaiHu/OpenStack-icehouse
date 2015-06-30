#!/bin/bash
args_len=$#
if [ $args_len == 0 ];then
	echo "USAGE: ./chkconfig.sh [options]	options: controller|compute"
	echo 'example: ./chkconfig.sh controller'
	exit
fi

#If in controller node

if [ $1 == "controller"  ];then
	#ntp 
	chkconfig ntpd on

	#mysql
	chkconfig mysqld on

	#rabbitmq
	chkconfig rabbitmq-server on

	#keystone
	chkconfig openstack-keystone on

	#glance
	chkconfig openstack-glance-api on
	chkconfig openstack-glance-registry on

	#nova
	chkconfig openstack-nova-api on
	chkconfig openstack-nova-cert on
	chkconfig openstack-nova-consoleauth on
	chkconfig openstack-nova-scheduler on
	chkconfig openstack-nova-conductor on
	chkconfig openstack-nova-novncproxy on

	#neutron
	chkconfig neutron-server on
	chkconfig openvswitch on
	chkconfig neutron-openvswitch-agent on
	chkconfig neutron-dhcp-agent on
	chkconfig neutron-metadata-agent on
	chkconfig neutron-l3-agent on

	#iptables
	chkconfig iptables off
	
elif [ $1 == "compute" ]
	#If in compute node
	#ntp 
	chkconfig ntpd on

	#neutron openvswitch	
	chkconfig openvswitch on
	
	#libvirt		
	chkconfig libvirtd on
	
	#messagebus	
	chkconfig messagebus on
	
	#nova	
	chkconfig openstack-nova-compute on
fi
