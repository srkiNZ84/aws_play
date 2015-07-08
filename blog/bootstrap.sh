#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Installing Wordpress pre-requisites..."
apt-get -y pwgen
MYSQL_ROOT_PW=`pwgen -s 20 1`
WP_DB=`pwgen -A0 8 1`
WP_DB_USER=`pwgen -A0 8 1`
WP_DB_PW=`pwgen -s 20 1`
echo mysql-server-5.6 mysql-server/root_password password $MYSQL_ROOT_PW | debconf-set-selections
echo mysql-server-5.6 mysql-server/root_password_again password $MYSQL_ROOT_PW | debconf-set-selections

#TODO: install Postfix and configure it as a satellite server to send through the main MTA

apt-get -y install apache2 libapache2-mod-php5 php5 mysql-client php5-gd php5-mysql libphp-phpmailer libphp-snoopy mysql-server
mysql -u root -p$MYSQL_ROOT_PW -e "CREATE DATABASE $WP_DB; GRANT ALL PRIVILEGES ON $WP_DB.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PW'; FLUSH PRIVILEGES;"
echo "Done"
echo "Installing Wordpress..."
rm -f /var/www/html/index.html
wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C /var/www/html/
mv /var/www/html/wordpress/* /var/www/html/
rm -rf /var/www/html/wordpress
echo "Done."
echo "Configuring Database connection..."
#TODO: Dump wp-config.php onto the machine
cat <<EOF > /var/www/html/wp-config.php
<?php
define('DB_NAME', '$WP_DB');
define('DB_USER', '$WP_DB_USER');
define('DB_PASSWORD', '$WP_DB_PW');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('AUTH_KEY',         'INT;tN];9@a7i-!7>D4DBmXL8ol;[a+6=bN K+:FGBX5YtYGVt<3b0 >54FwF*}L');
define('SECURE_AUTH_KEY',  'YHG!6h]<4&#aBs4<FN=hS].R;IGFOOmx-T&#wTD}%t,S=.zVZ@p2ilnhBI-b5HBY');
define('LOGGED_IN_KEY',    ',PvBw1NVEzA,.RraXKSH:.e2s&Ry$/E/HM+J4+c%p&VZB[{R[V)Xoo?p,jP,r|=|');
define('NONCE_KEY',        'CCRHk=aItX%mh6dY>mTB:|skQJ5vyT~}8s8.Qf< x^ZlYG,@D96 -ATg(^tCEf-J');
define('AUTH_SALT',        ',N7m+bUD-K|3y>=+sx9|V,M_F?Jy8?f+C}SQ:kkHTZ]/-D-bkvh*Ig>=4v~d+9wl');
define('SECURE_AUTH_SALT', 'CIu,G7^+q3LJ6<|-mN(8+:@}WDfgqjX+a<sh,s(YY=:Ts7HaTpGkO8&+BL)/I%;j');
define('LOGGED_IN_SALT',   ']0.MHk V_Z#-x0 Hc!BqY_%vloe?c=bI)DoY|gr7XxM5dY3_LO>9yJDq!N@6~-o;');
define('NONCE_SALT',       '>+m_DX&+TZ^vBWtZG#? ~IX*(R<%mBB/ Sw;j6EXS]Bn&&a(A:t}gY5+;);fqP~]');

\$table_prefix  = 'wp_';

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
  define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
?>
EOF
chown -R www-data:www-data /var/www/html/*
echo "Done."

#TODO: Register the DNS

#TODO: Change machine hostname and application URL
