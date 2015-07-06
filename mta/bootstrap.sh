#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Setting Postfix configuration..."
echo postfix postfix/mailname string dukic.co.nz | debconf-set-selections
echo postfix postfix/main_mailer_type select 'Internet Site' | debconf-set-selections
echo "Done."
echo "Installing Postfix..."
apt-get -y install postfix openssl-blacklist
echo "Done."
