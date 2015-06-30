#!/bin/sh

apt-get update
apt-get -y install fortune
fortune > /root/hello_world.txt
