#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Setting Postfix configuration..."
debconf-set-selections <<< "postfix postfix/mailname string dukic.co.nz"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
echo "Done."
echo "Installing Postfix..."
apt-get -y install postfix openssl-blacklist
echo "Done."
