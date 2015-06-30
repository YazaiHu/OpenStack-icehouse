#!/bin/bash
#定义安装包根目录
base_path=`pwd`

#安装epel、openstack-icehousei源
if [ ! -f '/etc/yum.repos.d/epel.repo' ];then
	epel_path=$base_path/yum/epel-release-6-8.noarch.rpm
	#安装epel源
	/usr/bin/yum install -y $epel_path
fi

#安装openstack-icehouse源
if [ ! -f '/etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-Icehouse' ];then
	cp $base_path/yum/RPM-GPG-KEY-RDO-Icehouse /etc/pki/rpm-gpg/
	rpm --import $base_path/yum/RPM-GPG-KEY-RDO-Icehouse
fi

if [ ! -f '/etc/yum.repos.d/rdo-release.repo' ];then
	cp $base_path/yum/rdo-release.repo /etc/yum.repos.d/
fi

/usr/bin/yum make clean
/usr/bin/yum makecache

/usr/bin/yum install yum-plugin-priorities -y

#安装ntp服务
/usr/bin/yum install -y ntp vim wget gcc gcc-c++ telnet iotop 
service ntpd start

#安装openstack-utils
/usr/bin/yum install -y openstack-utils


 
