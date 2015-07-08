#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Installing mysql..."
#echo mysql-server-5.6 mysql-server/root_password password letmein | debconf-set-selections
#echo mysql-server-5.6 mysql-server/root_password_again password letmein | debconf-set-selections
#apt-get -y install mysql-server
apt-get -y install gdebi-core
wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.4/mysql-cluster-gpl-7.4.6-debian7-x86_64.deb
gdebi --n mysql-cluster-gpl-7.4.6-debian7-x86_64.deb
echo "Done."
