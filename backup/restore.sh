#!/bin/bash
set -e
# debian packages
BACKUP_DIR=odn_backup
cp -R $BACKUP_DIR/deb/sources.list* /etc/apt/
apt-key add  $BACKUP_DIR/deb/repo.keys 
apt-get update

PACKAGE_LIST=$BACKUP_DIR/deb/packages.list
APT_PACKAGES_DEPENDENCIES=$BACKUP_DIR/deb/apt_packages.list
cat $PACKAGE_LIST  | grep openjdk-7-jre-headless | awk '{ print $2; }' > $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep python | awk '{ print $2"="$3; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep python-pip | awk '{ print $2; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep apache2-mpm-worker | awk '{ print $2; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep tomcat7 | awk '{ print $2; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep postgresql | awk '{ print $2; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep odn-* |  awk '{ print $2"="$3; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep unifiedviews-* | awk '{ print $2"="$3; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep virtuoso-opensource | awk '{ print $2"="$3; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep gettext| awk '{ print $2; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep odn-simple| awk '{ print $2"="$3; }' >> $APT_PACKAGES_DEPENDENCIES
cat $PACKAGE_LIST  | grep slapd | awk '{ print $2; }' >> $APT_PACKAGES_DEPENDENCIES
aptitude install -V $(cat $APT_PACKAGES_DEPENDENCIES | awk '{print $1}')

CKAN_DIR=$BACKUP_DIR/ckan
# odn-ckan-ic
service apache2 stop
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db clean -c /etc/odn-simple/odn-ckan-ic/production.ini
su - postgres -c "dropdb odn-ckan-ic" 
su - postgres -c "dropdb datastore-odn-ic" 
su - postgres -c "createdb  -O odn datastore-odn-ic"
su - postgres -c "createdb odn-ckan-ic" 
su - postgres -c "psql -d datastore-odn-ic" < $CKAN_DIR/datastore-odn-ic.sql
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan datastore set-permissions -c /etc/odn-simple/odn-ckan-ic/production.ini | su postgres -c psql
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db load $CKAN_DIR/odn-ckan-ic.sql -c /etc/odn-simple/odn-ckan-ic/production.ini 

# odn-ckan-pc
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db clean -c /etc/odn-simple/odn-ckan-pc/production.ini
su - postgres -c "dropdb odn-ckan-pc" 
su - postgres -c "dropdb datastore-odn-pc" 
su - postgres -c "createdb  -O odn datastore-odn-pc"
su - postgres -c "createdb odn-ckan-pc" 
su - postgres -c "psql -d datastore-odn-pc" < $CKAN_DIR/datastore-odn-pc.sql
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan datastore set-permissions -c /etc/odn-simple/odn-ckan-pc/production.ini | su postgres -c psql
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db load $CKAN_DIR/odn-ckan-pc.sql -c /etc/odn-simple/odn-ckan-pc/production.ini 
service apache2 start
# for update the tracking data and rebuild the search index - because popularity index
/usr/share/python/odn-ckan-shared/bin/paster  --plugin=ckan tracking update -c /etc/odn-simple/odn-ckan-ic/production.ini 
# update solr index for ic
/usr/share/python/odn-ckan-shared/bin/paster  --plugin=ckan search-index rebuild -r -c /etc/odn-simple/odn-ckan-ic/production.ini
# for update the tracking data and rebuild the search index - because popularity index
/usr/share/python/odn-ckan-shared/bin/paster  --plugin=ckan tracking update -c /etc/odn-simple/odn-ckan-pc/production.ini 
# update solr index for pc
/usr/share/python/odn-ckan-shared/bin/paster  --plugin=ckan search-index rebuild -r -c /etc/odn-simple/odn-ckan-pc/production.ini
# filestore
tar -xvf $CKAN_DIR/filestore-odn-ic.tar.gz  -C /
tar -xvf $CKAN_DIR/filestore-odn-pc.tar.gz  -C /
# dumps 
tar -xvf $BACKUP_DIR/dump/dumps.tar.gz -C /
# vocab if exists
tar -xvf $BACKUP_DIR/vocab/vocab.tar.gz -C / || true
# ldap
tar -xvf $BACKUP_DIR/ldap/ldap.tar.gz -C /
service slapd restart
# conf
tar -xvf $BACKUP_DIR/conf/conf.tar.gz -C /
service odn-midpoint stop
# idm 
tar -xvf $BACKUP_DIR/idm/midpoint.tar.gz -C /
su - postgres -c "dropdb midpoint" 
su - postgres -c "createdb  -O administrator midpoint" 
su - postgres -c "psql -d midpoint" <  $BACKUP_DIR/idm/midpoint.sql
su - postgres -c "psql -q -d midpoint -c \"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO administrator;\"" 
su - postgres -c "psql -q -d midpoint -c \"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO administrator;\"" 
service odn-midpoint start
# virtuoso
service virtuoso-opensource-7 stop
tar -xvf $BACKUP_DIR/virtuoso/virtuoso.tar.gz -C /
service virtuoso-opensource-7 start
# unifiedviews
tar -xvf $BACKUP_DIR/unifiedviews/dpus.tar.gz -C /
service unifiedviews-frontend stop
service unifiedviews-backend stop
su - postgres -c "dropdb unifiedviews" 
su - postgres -c "createdb  -O uv unifiedviews"
su - postgres -c "psql -d unifiedviews" <  $BACKUP_DIR/unifiedviews/unifiedviews.sql
su - postgres -c "psql -q -d unifiedviews -c \"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO uv;\""
su - postgres -c "psql -q -d unifiedviews -c \"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO uv;\""
service unifiedviews-frontend start
service unifiedviews-backend start




