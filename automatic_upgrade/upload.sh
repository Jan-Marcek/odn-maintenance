URL=https://127.0.0.1/internalcatalog/api/action

# create user at internal catalog
. /usr/share/python/odn-ckan-shared/bin/activate
paster --plugin=ckan user add admin password=admin email=admin@opendata.gov -c /etc/odn-simple/odn-ckan-ic/production.ini
API_KEY=`paster --plugin=ckan user admin -c /etc/odn-simple/odn-ckan-ic/production.ini | grep -oP 'apikey=\K\w+-\w+-\w+-\w+-\w+'`
paster --plugin=ckan sysadmin add admin -c /etc/odn-simple/odn-ckan-ic/production.ini
# do hacks to make possible to create dataset for organization comsode 
curl --insecure -H'Authorization:'$API_KEY $URL/organization_create -d '{"name":"comsode", "id":"comsode", "title":"comsode"}'
curl --insecure -H'Authorization:'$API_KEY $URL/user_create -d '{"name":"comsode", "id":"comsode", "fullname":"comsode", "email":"mail@mail.com", "password":"1234"}'
curl --insecure -H'Authorization:'$API_KEY $URL/member_create -d '{"id":"comsode", "object":"comsode", "object_type": "user","capacity":"user_capacity"}'
curl --insecure -H'Authorization:'$API_KEY $URL/member_create -d '{"id":"comsode", "object":"comsode", "object_type": "user","capacity":"user_capacity"}'

# create dataset sazp-slovak-protected-sites
ret=`curl --insecure -H'Authorization:'$API_KEY $URL/package_create -d ' {"license_title": "Open Data Commons Public Domain Dedication and License (PDDL)", "maintainer": "", "relationships_as_object": [], "private": false, "maintainer_email": "", "num_tags": 3, "metadata_created": "2015-07-27T13:05:31.318555", "metadata_modified": "2015-07-27T13:05:32.771089", "author": "", "author_email": "", "state": "active", "version": "", "creator_user_id": "f85f7688-62be-4abd-83f7-d9315d6ddd09", "type": "dataset", "resources": [], "num_resources": 1, "tags": [{"vocabulary_id": null, "state": "active", "display_name": "enviroment", "id": "d4400161-8295-4b11-957f-9dd9c105e126", "name": "enviroment"}, {"vocabulary_id": null, "state": "active", "display_name": "geography", "id": "777019b5-794d-4ba9-b7b3-ffd99604c054", "name": "geography"}, {"vocabulary_id": null, "state": "active", "display_name": "slovakia", "id": "5a4759f7-8c4b-40c5-af19-4e2ebd95a98c", "name": "slovakia"}], "tracking_summary": {"total": 16, "recent": 16}, "groups": [], "license_id": "odc-pddl", "relationships_as_subject": [], "name": "sazp-slovak-protected-sites", "isopen": true, "url": "A", "notes": "The data about Slovak protected sites includes:\r\n\r\nNational parks and protected landscape areas\r\nSmall scale protected areas\r\nProtected natural monuments\r\nSpecial protection areas: Bird directive\r\nSites of community importance: Habitat directive\r\nBiosphere reserves\r\nRamsar\r\nUNESCO world nature heritage sites\r\nProtected landscape elements\r\nMetadata: http://geoportal.gov.sk/sk/cat-client/detail.xml?uuid=9d6badaf-76c1-423f-97fb-030495d0a95d&serviceId=1", "owner_org": "comsode", "extras": [], "license_url": "http://www.opendefinition.org/licenses/odc-pddl", "title": "SA\u017dP: Slovak protected sites", "revision_id": "36fa9430-0cf3-4e2f-980f-41b3d860a403"}'`

DATASET_ID=`echo $ret | grep -oP '\"id\": \"\K\w+-\w+-\w+-\w+-\w+' | head -n 1 `

# add resource
curl -H'Authorization:'$API_KEY  $URL/resource_create --form upload=@sazp_resource.zip --form package_id=sazp-slovak-protected-sites --insecure --form url=http://sazp_protected_sites.zip --form name=sazp_protected_sites.zip

# create user at unifiedviews
su - postgres -c "psql -q -d unifiedviews -c \"INSERT INTO sch_email VALUES (3, 'comsode@nomail.com');\""
su - postgres -c "psql -q -d unifiedviews -c \"INSERT INTO usr_user VALUES (3, 'comsode', 3, '100000:6b2ac5049188af60429f643cd4074032fd1808237f0398791e7b9770e63dd1b6:92a1d80560d5fe77c3fafafc27da6c670d39badd1f132dc9f4317c23f43a3698', 'comsode', 20);\""
su - postgres -c "psql -q -d unifiedviews -c \"INSERT INTO usr_extuser VALUES (3, 'comsode');\""
su - postgres -c "psql -q -d unifiedviews -c \"INSERT INTO user_actor VALUES (1, 'casadmin', 'admin admin');\""

# import pipeline into unifiedviews
MASTER_USER=master
MASTER_PASS=commander
curl --user $MASTER_USER:$MASTER_PASS --fail  -X POST -H "Cache-Control: no-cache" -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW" -F file=@sazp_pipeline.zip http://localhost:28080/master/api/1/pipelines/import

# do some hacks to make pipeline visible for user casadmin
su - postgres -c "psql -q -d unifiedviews -c \"UPDATE ppl_model SET user_actor_id = 1;\""
su - postgres -c "psql -q -d unifiedviews -c \"UPDATE ppl_model SET user_id = 3;\""
su - postgres -c "psql -q -d odn-ckan-ic -c \"INSERT INTO pipelines VALUES ('"$DATASET_ID"', 1, 'SAZP: Protected sites');\""

# adjust labels and texts
cp theme/odn_theme_promoted.html /usr/share/python/odn-ckan-shared/lib/python2.7/site-packages/ckanext/odn_theme/templates/home/snippets/odn_theme_promoted.html
cp theme/odn_theme.css /usr/share/python/odn-ckan-shared/lib/python2.7/site-packages/ckanext/odn_theme/public/css/odn_theme.css
cp theme/header.html /usr/share/python/odn-ckan-shared/lib/python2.7/site-packages/ckanext/odn_theme/templates/header.html
cp theme/messages.properties  /usr/share/odn-cas/webapps/cas/WEB-INF/classes/messages.properties
sed -i "s/SSLCertificateFile  .*/SSLCertificateFile   \/etc\/apache2\/ssl\/STAR_comsode_eu.crt/"  /etc/apache2/sites-enabled/odn-simple-ssl
sed -i "s/SSLCertificateKeyFile .*/SSLCertificateKeyFile   \/etc\/apache2\/ssl\/comsode.eu-key.pem \n  SSLCertificateChainFile     \/etc\/apache2\/ssl\/comodo-CA-bundle.crt/"  /etc/apache2/sites-enabled/odn-simple-ssl


service odn-cas restart
service apache2 restart