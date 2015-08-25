# unifiedviews
## backend
/etc/init.d/unifiedviews_backend 
/var/lib/unifiedviews/common/
/usr/share/unifiedviews
/var/cache/unifiedviews/backend/working
/etc/unifiedviews/unifiedviews.conf
/usr/sbin/run_unifiedviews_backend


/etc/default/tomcat7 
/etc/apache2
/etc/odn-cas
/etc/odn-midpoint
/etc/odn-simple
/etc/odn-solr
/var/lib/odn-ckan-ic
/var/lib/odn-ckan-pc
/var/lib/odn-solr
/var/lib/ldap_odn
/var/lib/virtuoso-opensource-7
/var/lib/midpoint.home


cat deb/deb_all  | grep odn-* |  awk '{ print $2"="$3; }' > list
cat deb/deb_all  | grep openjdk-7-jre-headless | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep tomcat7 | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep unifiedviews-* | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep virtuoso-opensource | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep postgresql | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep apache2-mpm-worker | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep python-pip | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep gettext| awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep odn-simple| awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep slapd | awk '{ print $2"="$3; }' >> list
cat deb/deb_all  | grep python | awk '{ print $2"="$3; }' >> list


dpkg --get-selections > /backup/package-selections
dpkg --set-selections < /backup/package-selections
apt-get dselect-upgrade

#odn-ckan-ic
service apache2 stop
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db clean odn-ckan-ic.sql -c /etc/odn-simple/odn-ckan-ic/production.ini
su - postgres -c "psql -q -d ${dbname} -c \"DROP DATABASE odn-ckan-ic;\"" 
su - postgres -c "createdb  -O odn odn-ckan-ic"
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db load odn-ckan-ic.sql -c /etc/odn-simple/odn-ckan-ic/production.ini 
#odn-ckan-pc
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db clean odn-ckan-pc.sql -c /etc/odn-simple/odn-ckan-pc/production.ini
su - postgres -c "psql -q -d ${dbname} -c \"DROP DATABASE odn-ckan-pc;\"" 
su - postgres -c "createdb  -O odn odn-ckan-pc"
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan db load odn-ckan-pc.sql -c /etc/odn-simple/odn-ckan-pc/production.ini 
su - postgres -c "psql -q -d ${dbname} -c \"DROP DATABASE datastore-odn-ic;\"" 
su - postgres -c "createdb  -O odn datastore-odn-ic"
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan datastore set-permissions -c /etc/odn-simple/odn-ckan-ic/production.ini | su postgres -c psql
su - postgres -c "psql -q -d ${dbname} -c \"DROP DATABASE datastore-odn-pc;\"" 
su - postgres -c "createdb  -O odn datastore-odn-pc"
/usr/share/python/odn-ckan-shared/bin/paster --plugin=ckan datastore set-permissions -c /etc/odn-simple/odn-ckan-pc/production.ini | su postgres -c psql
service apache2 start


aptitude install $(cat /backup/package-selections | awk '{print $1}')
#restore unifiedviews
apt-get install  unifiedviews-backend-shared=2.1.0
apt-get install  unifiedviews-backend-pgsql=2.1.0
apt-get install  unifiedviews-backend=2.1.0
apt-get install  unifiedviews-webapp-shared=2.1.0
apt-get install  unifiedviews-webapp-pgsql=2.1.0
apt-get install  unifiedviews-webapp=2.1.0
apt-get install  unifiedviews-pgsql=2.1.0
service unifiedviews-frontend stop
service unifiedviews-backend stop
cp -r var/ /
apt-get install odn-simple
cp ldap_odn /var/lib/ldap_odn/ -R
chown openldap:openldap /var/lib/ldap_odn/ -R
service slapd restart
chown unifiedviews:unifiedviews -R  /var/lib/unifiedviews/common/dpu/
usrname=uv
dbname=unifiedviews
su - postgres -c "createdb  -O ${usrname} ${dbname}"
su - postgres -c "psql -d unifiedviews" < /root/unifiedviews/unifiedviews.sql
su - postgres -c "psql -q -d ${dbname} -c \"GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${usrname};\""
su - postgres -c "psql -q -d ${dbname} -c \"GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${usrname};\""
service unifiedviews-frontend start
service unifiedviews-backend start





