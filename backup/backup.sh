#!/bin/bash
set -e
# set where BACKUP shall be placed
if [ $# -eq 0 ]
  then
    echo "ERROR: Path where backup file will be placed is missing"
    echo "example of usage:  ./backup /opt/"
    exit -1
fi

if [ ! -d "$1" ]; then
    echo "ERROR: $1 is file or directory is not exist"
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
tar -zcvpf $BACKUP_DIR_UV/dpus.tar.gz /var/lib/unifiedviews/common
su - postgres -c "pg_dump unifiedviews --inserts" > $BACKUP_DIR_UV/unifiedviews.sql
# ckan ic, pc,  
echo "ckan"
BACKUP_DIR_CKAN=$BACKUP_TMP_DIR/ckan
mkdir -p $BACKUP_DIR_CKAN
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db dump $BACKUP_DIR_CKAN/odn-ckan-ic.sql -c /etc/odn-simple/odn-ckan-ic/production.ini
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db dump $BACKUP_DIR_CKAN/odn-ckan-pc.sql -c /etc/odn-simple/odn-ckan-pc/production.ini
# datastore-odn-ic, datastore-odn-pc
su - postgres -c "pg_dump datastore-odn-ic --inserts" > $BACKUP_DIR_CKAN/datastore-odn-ic.sql
su - postgres -c "pg_dump datastore-odn-pc --inserts" > $BACKUP_DIR_CKAN/datastore-odn-pc.sql
# filestore-odn-ic, filestore-odn-pc 
tar -zcvpf $BACKUP_DIR_CKAN/filestore-odn-ic.tar.gz /var/lib/odn-ckan-ic/
tar -zcvpf $BACKUP_DIR_CKAN/filestore-odn-pc.tar.gz /var/lib/odn-ckan-pc/
# dumps
echo "dumps"
BACKUP_DIR_DUMP=$BACKUP_TMP_DIR/dump
mkdir -p $BACKUP_DIR_DUMP
tar -zcvpf $BACKUP_DIR_DUMP/dumps.tar.gz  /var/www/dump

# ldap
echo "LDAP"
BACKUP_DIR_LDAP=$BACKUP_TMP_DIR/ldap
mkdir -p $BACKUP_DIR_LDAP
tar -zcvpf $BACKUP_DIR_LDAP/ldap.tar.gz /var/lib/ldap_odn

# conf
echo "conf"
BACKUP_DIR_CONF=$BACKUP_TMP_DIR/conf
mkdir -p $BACKUP_DIR_CONF
tar -zcvpf $BACKUP_DIR_CONF/conf.tar.gz /etc/default/tomcat7  /etc/apache2  /etc/odn-cas /etc/odn-midpoint  /etc/odn-simple  /etc/odn-solr  /etc/unifiedviews

# idm
echo "idm"
BACKUP_DIR_IDM=$BACKUP_TMP_DIR/idm
mkdir -p $BACKUP_DIR_IDM
tar -zcvpf $BACKUP_DIR_IDM/midpoint.home.tar.gz /var/lib/midpoint.home
su - postgres -c "pg_dump midpoint --inserts" > $BACKUP_DIR_IDM/midpoint.sql
# apt debian packages
echo "apt debian packages"
APT_PACKAGE=$BACKUP_TMP_DIR/deb
mkdir -p $APT_PACKAGE
dpkg -l >  $APT_PACKAGE/packages.list
cp -pR /etc/apt/sources.list* $APT_PACKAGE/
apt-key exportall > $APT_PACKAGE/repo.keys
# virtuoso
echo "virtuoso"
BACKUP_DIR_VIRTUOSO=$BACKUP_TMP_DIR/virtuoso
mkdir -p $BACKUP_DIR_VIRTUOSO
tar -zcvpf  $BACKUP_DIR_VIRTUOSO/virtuoso.tar.gz /var/lib/virtuoso-opensource-7
# vocab
BACKUP_DIR_VOCAB=$BACKUP_TMP_DIR/vocab
if [ -d /var/www/vocab]; then 
    echo "vocab"
    mkdir -p $BACKUP_DIR_VOCAB
    tar -zcvpf  $BACKUP_DIR_VOCAB/vocab.tar.gz /var/www/vocab
fi

# final backup file
echo "create backup file: $BACKUP_NAME"
cd $BACKUP_PATH
tar -zcvpf  $BACKUP_PATH/$BACKUP_NAME.tar.gz $BACKUP_NAME
timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
echo "clean tmp files"
rm -rf $BACKUP_TMP_DIR
echo "backup file: $BACKUP_PATH/$BACKUP_NAME.tar.gz was successfully created on: $timestamp"
exit 0