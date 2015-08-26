#!/bin/bash
set -e
# set where BACKUP shall be placed
if [ $# -eq 0 ]
  then
    echo "ERROR: Path where backup file will be placed is missing"
    echo "example of usage:  ./backup /opt/"
    exit -1
fi

BACKUP_PATH=$1
timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
BACKUP_NAME=odn_backup_$timestamp
echo "start: "$timestamp
BACKUP_TMP_DIR=$BACKUP_PATH/$BACKUP_NAME
mkdir -p $BACKUP_TMP_DIR
# unifiedviews
echo "unifiedviews"
BACKUP_DIR_UV=$BACKUP_TMP_DIR/unifiedviews
mkdir -p $BACKUP_DIR_UV
zip -r $BACKUP_DIR_UV/dpus.zip /var/lib/unifiedviews/common
su - postgres -c "pg_dump unifiedviews --inserts" > $BACKUP_DIR_UV/unifiedviews.sql
# ckan ic, pc,  datastore-odn-ic, datastore-odn-pc
echo "ckan"
BACKUP_DIR_CKAN=$BACKUP_TMP_DIR/ckan
mkdir -p $BACKUP_DIR_CKAN
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db dump $BACKUP_DIR_CKAN/odn-ckan-ic.sql -c /etc/odn-simple/odn-ckan-ic/production.ini
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db dump $BACKUP_DIR_CKAN/odn-ckan-pc.sql -c /etc/odn-simple/odn-ckan-pc/production.ini
su - postgres -c "pg_dump datastore-odn-ic --inserts" > $BACKUP_DIR_CKAN/datastore-odn-ic.sql
su - postgres -c "pg_dump datastore-odn-pc --inserts" > $BACKUP_DIR_CKAN/datastore-odn-pc.sql
# ldap
echo "LDAP"
BACKUP_DIR_LDAP=$BACKUP_TMP_DIR/ldap
mkdir -p $BACKUP_DIR_LDAP
zip -r $BACKUP_DIR_LDAP/ldap.zip /var/lib/ldap_odn
# conf
echo "conf"
BACKUP_DIR_CONF=$BACKUP_TMP_DIR/conf
mkdir -p $BACKUP_DIR_CONF
zip -r  $BACKUP_DIR_CONF/conf.zip /etc/default/tomcat7  /etc/apache2  /etc/odn-cas /etc/odn-midpoint  /etc/odn-simple  /etc/odn-solr  /etc/unfiedviews
# idm
echo "idm"
BACKUP_DIR_IDM=$BACKUP_TMP_DIR/idm
mkdir -p $BACKUP_DIR_IDM
zip -r $BACKUP_DIR_IDM/midpoint.home.zip /var/lib/midpoint.home
su - postgres -c "pg_dump midpoint --inserts" > $BACKUP_DIR_IDM/midpoint.sql
# apt debian packages
echo "apt debian packages"
APT_PACKAGE=$BACKUP_TMP_DIR/deb
mkdir -p $APT_PACKAGE
dpkg -l >  $APT_PACKAGE/packages.list
cp -R /etc/apt/sources.list* $APT_PACKAGE/
apt-key exportall > $APT_PACKAGE/repo.keys
# virtuoso
echo "virtuoso"
BACKUP_DIR_VIRTUOSO=$BACKUP_TMP_DIR/virtuoso
mkdir -p $BACKUP_DIR_VIRTUOSO
zip -r $BACKUP_DIR_VIRTUOSO/virtuoso.zip /var/lib/virtuoso-opensource-7
# final backup file
echo "create backup file: $BACKUP_NAME"
cd $BACKUP_PATH
zip -r $BACKUP_PATH/$BACKUP_NAME.zip $BACKUP_NAME
timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
echo "clean tmp files"
rm -rf $BACKUP_TMP_DIR
echo "successfully end: "$timestamp
