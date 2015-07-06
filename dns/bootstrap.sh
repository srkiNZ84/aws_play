#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting fortune to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."

echo "Installing BIND..."
apt-get -y install bind9
echo "Done."

echo "Setting up the configuration..."
# Create the public zone file
cat <<EOF > /etc/bind/named.conf.public-zones
zone "dukic.co.nz" {
	type master;
	file "/etc/bind/db.dukic.co.nz";
};

//zone "127.in-addr.arpa" {
//	type master;
//	file "/etc/bind/db.127";
//};
EOF

#TODO: rewrite script to put IP's of Instances instead of the hard coded values
#TODO: also, need to make sure it's the public and not private IP
# Create the dukic.co.nz DNS db file
cat <<EOF > /etc/bind/db.dukic.co.nz
;
; BIND data file for local loopback interface
;
\$TTL	604800
@	IN	SOA	ns1.dukic.co.nz. admin.dukic.co.nz. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	ns1.dukic.co.nz.
@	IN	A	10.159.95.235
@	IN	AAAA	::1
ns1	IN	A	10.159.95.235
EOF

# Include the public zone file
echo "include \"/etc/bind/named.conf.public-zones\";" >> /etc/bind/named.conf

echo "Restarting BIND..."
service bind9 restart
echo "All done... please test :-)"
