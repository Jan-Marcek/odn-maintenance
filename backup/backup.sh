#!/bin/bash
BACKUP_DIR=/tmp/backup
timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
echo "start: "$timestamp
BACKUP_DIR=/tmp/backup_$timestamp
mkdir -p $BACKUP_DIR
BACKUP_DIR_UV=$BACKUP_DIR/unifiedviews
mkdir -p $BACKUP_DIR_UV
#zip $BACKUP_DIR_UV/backend-init.zip  /etc/init.d/unifiedviews-backend /etc/unifiedviews/unifiedviews.conf /usr/sbin/run_unifiedviews_backend
zip -r $BACKUP_DIR_UV/dpus.zip /var/lib/unifiedviews/common
#zip -r $BACKUP_DIR_UV/binaries.zip /usr/share/unifiedviews
su - postgres -c "pg_dump unifiedviews --inserts" > $BACKUP_DIR_UV/unifiedviews.sql
BACKUP_DIR_CKAN=$BACKUP_DIR/ckan
mkdir -p $BACKUP_DIR_CKAN
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db dump $BACKUP_DIR_CKAN/odn-ckan-ic.sql -c /etc/odn-simple/odn-ckan-ic/production.ini
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db dump $BACKUP_DIR_CKAN/odn-ckan-pc.sql -c /etc/odn-simple/odn-ckan-pc/production.ini

BACKUP_DIR_LDAP=$BACKUP_DIR/ldap
mkdir -p $BACKUP_DIR_LDAP
zip -r $BACKUP_DIR_LDAP /var/lib/ldap_odn

BACKUP_DIR_CONF=$BACKUP_DIR/conf
mkdir -p $BACKUP_DIR_CONF
zip -r  $BACKUP_DIR_CONF /etc/default/tomcat7  /etc/apache2  /etc/odn-cas /etc/odn-midpoint  /etc/odn-simple  /etc/odn-solr  /etc/unfiedviews

DEB_ODN=$BACKUP_DIR/deb
mkdir -p $DEB_ODN
DEB_ALL=$DEB_ODN/deb_all
touch $DEB_ALL
dpkg -l >  $DEB_ALL

timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
echo "successfully end: "$timestamp
