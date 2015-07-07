#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Installing Wordpress pre-requisites..."
apt-get -y install apache2 libapache2-mod-php5 php5 mysql-client php5-gd php5-mysql libphp-phpmailer libphp-snoopy
echo "Done"
echo "Installing Wordpress..."
rm -f /var/www/html/index.html
wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C /var/www/html/
mv /var/www/html/wordpress/* /var/www/html/
rm -rf /var/www/html/wordpress
echo "Done."
echo "Configuring Database connection..."
#TODO: Dump wp-config.php onto the machine

#TODO: Register the DNS
