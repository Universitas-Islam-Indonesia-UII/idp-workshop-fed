FROM ubuntu:22.04
LABEL maintainer="pandu.asmoro@uii.ac.id"
ARG DEBIAN_FRONTEND=noninteractive

ARG openjdk=openjdk-11-jre
ARG openjdk_home=/usr/lib/jvm/java-1.11.0-openjdk-amd64

ENV TOMCAT=tomcat9
ENV TZ=Asia/Jakarta
ENV JAVA_HOME=${openjdk_home}
ENV CATALINA_HOME=/usr/share/${TOMCAT}
ENV CATALINA_BASE=/var/lib/${TOMCAT}
ENV PATH=$CATALINA_HOME/bin:$PATH

COPY shibboleth-identity-provider-4.0.1.tar.gz /tmp/

RUN sed -i 's|archive.ubuntu.com|repo.ugm.ac.id|g' /etc/apt/sources.list && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt update && \
	apt upgrade -y && \
    apt install -y nano ntp curl wget sudo openssl ${openjdk} supervisor expect apache2 ${TOMCAT} libcommons-dbcp-java libcommons-pool-java ca-certificates-java && \
    mkdir -p /var/log/supervisor && \
    mkdir -p $CATALINA_BASE/lib/org/apache/catalina/util/ && \
    echo 'server.info=' >> $CATALINA_BASE/lib/org/apache/catalina/util/ServerInfo.properties && \
    chown root:tomcat /etc/${TOMCAT}/ -R && \
    cd /tmp && \
    tar -xzf shibboleth-identity-provider-4.0.1.tar.gz && \
    cd shibboleth-identity-provider-4.0.1 && \
    ln -s /usr/share/java/mysql-connector-java.jar /tmp/shibboleth-identity-provider-4.0.1/webapp/WEB-INF/lib && \
    ln -s /usr/share/java/commons-dbcp.jar /tmp/shibboleth-identity-provider-4.0.1/webapp/WEB-INF/lib && \
    ln -s /usr/share/java/commons-pool.jar /tmp/shibboleth-identity-provider-4.0.1/webapp/WEB-INF/lib

COPY supervisord.conf /etc/supervisor/conf.d/
COPY server.xml /etc/${TOMCAT}/
COPY context.xml /etc/${TOMCAT}/
COPY jstl-1.2.jar /tmp
COPY web.xml /tmp
COPY ldap.properties /tmp
COPY default-ssl.conf /etc/apache2/sites-available/
COPY idp.xml /etc/tomcat9/Catalina/localhost/
COPY idp.conf /etc/apache2/sites-available/
COPY shib-restart.sh /root/
COPY start.sh /root/

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/apache-selfsigned.key -out /etc/apache2/apache-selfsigned.crt -subj "/C=ID/O=Federasi ID/CN=federasi.id" && \
	a2enmod proxy_http ssl headers alias include negotiation proxy_ajp rewrite remoteip && \
    a2ensite default-ssl.conf idp.conf && \
    printf '%s\n%s\n' 'ServerSignature Off' 'ServerTokens Prod' >> /etc/apache2/apache2.conf

RUN chown -R tomcat:tomcat /var/lib/${TOMCAT} /var/log/${TOMCAT} && \
	chmod a+x /root/shib-restart.sh && \
    chmod a+x /root/start.sh

EXPOSE 443

WORKDIR /opt/shibboleth-idp

ENTRYPOINT ["sh", "/root/start.sh"]