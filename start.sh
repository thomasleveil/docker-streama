#!/bin/bash

if [ -z "$MYSQL_PORT_3306_TCP_ADDR" ]; then
	echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
	echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
	exit 1
fi
: ${MYSQL_PORT_3306_TCP_PORT:=3306}

: ${STREAMA_DB_NAME:=streama}
: ${STREAMA_DB_USER:=root}
if [ "$STREAMA_DB_USER" = 'root' ]; then
	: ${STREAMA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi

if [ -z "$STREAMA_DB_PASSWORD" ]; then
	echo >&2 'error: missing required STREAMA_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e STREAMA_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be STREAMA_DB_USER and STREAMA_DB_NAME.)'
	exit 1
fi

# Check if database already exists
RESULT=`mysql -u${STREAMA_DB_USER} -p${STREAMA_DB_PASSWORD} \
	-h${MYSQL_PORT_3306_TCP_ADDR} -P${MYSQL_PORT_3306_TCP_PORT} \
	--skip-column-names -e "SHOW DATABASES LIKE '${STREAMA_DB_NAME}'"`

if [ "$RESULT" != $STREAMA_DB_NAME ]; then
	# mysql database does not exist, create it
	echo "Creating database ${STREAMA_DB_NAME}"

	mysql -u${STREAMA_DB_USER} -p${STREAMA_DB_PASSWORD} \
	 -h${MYSQL_PORT_3306_TCP_ADDR} -P ${MYSQL_PORT_3306_TCP_PORT} \
	 -e "CREATE DATABASE ${STREAMA_DB_NAME}"
fi


cat <<- EOF > grails-app/conf/DataSource.groovy
dataSource {
    pooled = true
    jmxExport = true
    driverClassName = "org.h2.Driver"
    username = "sa"
    password = ""
}
hibernate {
    cache.use_second_level_cache = true
    cache.use_query_cache = false
    cache.region.factory_class = 'org.hibernate.cache.ehcache.EhCacheRegionFactory' // Hibernate 4
    singleSession = true // configure OSIV singleSession mode
    flush.mode = 'manual' // OSIV session flush mode outside of transactional context
}

// environment specific settings
environments {
      production {
        dataSource {
          dbCreate = "update"
          driverClassName = "com.mysql.jdbc.Driver"
          dialect = org.hibernate.dialect.MySQL5InnoDBDialect

          //DEV
          url = "jdbc:mysql://${MYSQL_PORT_3306_TCP_ADDR}:${MYSQL_PORT_3306_TCP_PORT}/${STREAMA_DB_NAME}"
          username = "${STREAMA_DB_USER}"
          password = "${STREAMA_DB_PASSWORD}"

            properties {
               // See http://grails.org/doc/latest/guide/conf.html#dataSource for documentation
               jmxEnabled = true
               initialSize = 5
               maxActive = 50
               minIdle = 5
               maxIdle = 25
               maxWait = 10000
               maxAge = 10 * 60000
               timeBetweenEvictionRunsMillis = 5000
               minEvictableIdleTimeMillis = 60000
               validationQuery = "SELECT 1"
               validationQueryTimeout = 3
               validationInterval = 15000
               testOnBorrow = true
               testWhileIdle = true
               testOnReturn = false
               jdbcInterceptors = "ConnectionState"
               defaultTransactionIsolation = java.sql.Connection.TRANSACTION_READ_COMMITTED
            }
        }
    }
}
EOF

grails prod run-app
