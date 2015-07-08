#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Installing 389 Server, Dogtag and freeIPA..."
echo "Done."
