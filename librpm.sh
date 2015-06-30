#安装mysql服务
base_path=`pwd`

if [ $# == 0 ];then
	echo "password is must to input"
	exit
fi

if [ $# != 2 ];then
	echo "args length is wrong"
	exit
fi

listen_ip=$1
mysql_pass=$2

#install mysql service 
yum install -y mysql mysql-server MySQL-python python-devel
service mysqld start

#mysql_install_db

#设置root密码
/usr/bin/mysqladmin -u root  password $mysql_pass

mysql -uroot -p$mysql_pass -e "DELETE FROM mysql.user where User=''"
mysql -uroot -p$mysql_pass -e "DELETE FROM mysql.user where Password=''"
mysql -uroot -p$mysql_pass -e "GRANT ALL PRIVILEGES ON mysql.* TO 'root'@'localhost' IDENTIFIED BY '${mysql_pass}'"
mysql -uroot -p$mysql_pass -e "FLUSH PRIVILEGES"
#mysql_secure_installation

cp -f $base_path/conf/mysql/my.cnf /etc/
sed -i "s/LISTENIP/${listen_ip}/" /etc/my.cnf

#重启mysql服务
service mysqld restart

#安装rabbitmq
yum install -y  rabbitmq-server
service rabbitmq-server start

#安装iproute
yum install -y iproute

#关闭防火墙
service iptables stop
