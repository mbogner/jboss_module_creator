#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "${DIR}" || exit 1

TARGET=target
DOWNLOADS=downloads
VERSION=42.2.23
NAME=postgresql-${VERSION}
JAR=${NAME}.jar
BASE_PACKAGE=org
PACKAGE=${BASE_PACKAGE}/postgresql/driver/main
MODULE=org.postgresql.driver
ZIP=module-${NAME}.zip

rm -rf ${TARGET}
mkdir -p ${TARGET}/${PACKAGE} ${DOWNLOADS}

if [[ ! -e ${DOWNLOADS}/${JAR} ]]; then
  wget https://jdbc.postgresql.org/download/${JAR} -O ${DOWNLOADS}/${JAR}
fi

cp ${DOWNLOADS}/${JAR} ${TARGET}/${PACKAGE}/
cat <<MODULEXML > ${TARGET}/${PACKAGE}/module.xml
<?xml version="1.0" encoding="UTF-8"?>
<module xmlns="urn:jboss:module:1.0" name="${MODULE}">
    <resources>
        <resource-root path="${JAR}"/>
    </resources>
    <dependencies>
        <module name="javax.api"/>
        <module name="javax.transaction.api"/>
    </dependencies>
</module>
MODULEXML

cat <<DRIVER;
######################
# You can use the following driver section:
######################

<driver name="postgresql" module="org.postgresql.driver">
	<xa-datasource-class>org.postgresql.xa.PGXADataSource</xa-datasource-class>
</driver>

######################
# And here is an example datasource
######################

<datasource jndi-name="java:jboss/datasources/TestDS" pool-name="TESTDS"
	enabled="true" jta="true" use-java-context="true" use-ccm="true">
	<connection-url>jdbc:postgresql:test</connection-url>
	<driver>postgresql</driver>
	<pool>
		<min-pool-size>5</min-pool-size>
		<max-pool-size>25</max-pool-size>
		<prefill>false</prefill>
		<use-strict-min>false</use-strict-min>
		<flush-strategy>FailingConnectionOnly</flush-strategy>
	</pool>
	<security>
		<user-name>someuser</user-name>
		<password>somepass</password>
	</security>
	<validation>
		<check-valid-connection-sql>SELECT 1</check-valid-connection-sql>
		<validate-on-match>false</validate-on-match>
		<background-validation>false</background-validation>
		<use-fast-fail>false</use-fast-fail>
	</validation>
</datasource>

######################
DRIVER

cd ${TARGET} || exit 2
zip -r ${ZIP} ${BASE_PACKAGE} >> /dev/null 2>&1 || exit 3

echo "done - see ${TARGET}/${ZIP}"
