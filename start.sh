#!/bin/bash

yes "" | /tmp/shibboleth-identity-provider-4.0.1/bin/install.sh -Didp.keystore.password=federasi -Didp.sealer.password=federasi -Didp.host.name=${DOMAIN}
cp /tmp/jstl-1.2.jar /var/lib/${TOMCAT}/lib/
mv /tmp/jstl-1.2.jar /opt/shibboleth-idp/edit-webapp/WEB-INF/lib/
mv /tmp/web.xml /opt/shibboleth-idp/edit-webapp/WEB-INF/classes/
mv /tmp/ldap.properties /opt/shibboleth-idp/conf/

sed -i "s|DOMAIN_ENV|$DOMAIN|g" /etc/apache2/sites-available/default-ssl.conf
sed -i "s|LDAP_URL_ENV|${LDAP_URL}|g; \
	s|LDAP_BASEDN_ENV|${LDAP_BASEDN}|g; \
	s|LDAP_BINDDN_ENV|${LDAP_BINDDN}|g" /opt/shibboleth-idp/conf/ldap.properties
sed -i "s|myServicePassword|${LDAP_PASSWORD}|g" /opt/shibboleth-idp/credentials/secrets.properties
sed -i "s|2023|2024|g" /opt/shibboleth-idp/metadata/idp-metadata.xml

yes "" | /opt/shibboleth-idp/bin/build.sh

chown -R tomcat:tomcat /opt/shibboleth-idp

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
/etc/init.d/apache2 start
sleep 30
tail -F /opt/shibboleth-idp/logs/idp-process.log