#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Installing Wordpress pre-requisites..."
apt-get -y install apache2 libapache2-mod-php5 php5 mysql-client mariadb-client php5-gd php5-mysql libphp-phpmailer libphp-snoopy
echo "Done"
