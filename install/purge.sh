#!/bin/bash
service apache2 stop
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db clean -c /etc/odn-simple/odn-ckan-ic/production.ini || true
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db clean -c /etc/odn-simple/odn-ckan-pc/production.ini || true
echo "DROP DATABASE odn-ckan-ic"
su - postgres -c "dropdb odn-ckan-ic" || true
su - postgres -c "dropdb datastore-odn-ic" || true
# drop database of odn-ckan-pc
echo "DROP DATABASE odn-ckan-pc"
su - postgres -c "dropdb odn-ckan-pc" || true
su - postgres -c "dropdb datastore-odn-pc" || true

apt-get purge -y odn-simple
apt-get purge -y odn-solr
apt-get purge -y odn-uv-plugins
apt-get purge -y unifiedviews-plugins
apt-get purge -y unifiedviews-pgsql 
apt-get purge -y unifiedviews-webapp 
apt-get purge -y unifiedviews-webapp-pgsql 
apt-get purge -y unifiedviews-webapp-shared 
apt-get purge -y unifiedviews-backend 
apt-get purge -y unifiedviews-backend-pgsql 
apt-get purge -y unifiedviews-backend-shared
service virtuoso-opensource-7 stop
apt-get purge -y virtuoso-opensource-7
apt-get purge -y virtuoso-opensource
apt-get purge -y virtuoso-opensource-7-bin
apt-get purge -y virtuoso-opensource-7-common
apt-get purge -y virtuoso-server
apt-get purge -y virtuoso-vad-conductor
apt-get purge -y virtuoso-vsp-startpage
update-rc.d virtuoso-opensource-7 remove
rm -rf /var/lib/virtuoso-opensource-7
apt-get purge -y odn-midpoint
apt-get purge -y odn-cas
apt-get purge -y odn-ckan-shared
apt-get purge -y slapd

apt-get autoremove -y