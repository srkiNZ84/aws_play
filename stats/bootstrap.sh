#!/bin/sh

echo "Updating..."
apt-get update
echo "Installing fortune..."
apt-get -y install fortune
echo "Outputting to file..."
/usr/games/fortune > /root/hello_world.txt
echo "Done."
echo "Installing Graphite..."
apt-get -y install graphite-web graphite-carbon apache2 openssl-blacklist libapache2-mod-wsgi pwgen sqlite3
cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available/100-graphite.conf
GENERATED_KEY=`pwgen -cn 30 1`
sed -i -e "s/UNSAFE_DEFAULT/$GENERATED_KEY/" /etc/graphite/local_settings.py
sed -i -e "s/#SECRET_KEY/SECRET_KEY/" /etc/graphite/local_settings.py
sed -i -e "s/#TIME_ZONE = 'America\/Los_Angeles'/TIME_ZONE = 'Pacific\/Auckland'/" /etc/graphite/local_settings.py
a2dissite 000-default
a2ensite 100-graphite
graphite-manage syncdb --noinput
ADMINPASS=`pwgen -cn 30 1`
echo $ADMINPASS > /root/graphite-creds.txt
graphite-manage createsuperuser --noinput --username=srdan --email=srdan@dukic.co.nz
graphite-manage shell <<EOF
from django.contrib.auth.models import User
usr = User.objects.get(username='srdan')
usr.set_password('$ADMINPASS')
usr.save()
exit()
EOF
chown -R _graphite /var/lib/graphite
service apache2 restart
