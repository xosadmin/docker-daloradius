#!/bin/bash

if [[ -z "$MYSQL_SERVER" ]] || [[ -z "$MYSQL_PORT" ]] || [[ -z "$MYSQL_USER" ]] || [[ -z "$MYSQL_PASSWORD" ]] || [[ -z "$MYSQL_DBNAME" ]]; then
    echo "Error: Insufficient MySQL connection information." >&2
    exit 1
fi

if [[ ! -f "/etc/daloradius.lock" ]]; then
    cd "/var/www/daloradius/contrib/db" || { echo "Failed to cd to daloRADIUS db dir"; exit 1; }

    if ! mysql -h"$MYSQL_SERVER" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DBNAME" < fr3-mariadb-freeradius.sql; then
        echo "Failed to import fr3-mariadb-freeradius.sql" >&2
        exit 1
    fi

    if ! mysql -h"$MYSQL_SERVER" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DBNAME" < mariadb-daloradius.sql; then
        echo "Failed to import mariadb-daloradius.sql" >&2
        exit 1
    fi

    cat <<EOF > /etc/apache2/envvars
export APACHE_RUN_USER=www-data
export APACHE_RUN_GROUP=www-data
export APACHE_PID_FILE=/var/run/apache2/apache2.pid
export APACHE_RUN_DIR=/var/run/apache2
export APACHE_LOCK_DIR=/var/lock/apache2
export APACHE_LOG_DIR=/var/log/apache2
export DALORADIUS_USERS_PORT=80
export DALORADIUS_OPERATORS_PORT=8000
export DALORADIUS_ROOT_DIRECTORY=/var/www/daloradius
export DALORADIUS_SERVER_ADMIN=admin@daloradius.local
EOF

    cat <<EOF > /etc/apache2/ports.conf
Listen \${DALORADIUS_USERS_PORT}
Listen \${DALORADIUS_OPERATORS_PORT}
EOF

    cat <<EOF > /etc/apache2/sites-available/operators.conf
<VirtualHost *:\${DALORADIUS_OPERATORS_PORT}>
ServerAdmin \${DALORADIUS_SERVER_ADMIN}
DocumentRoot \${DALORADIUS_ROOT_DIRECTORY}/app/operators

<Directory \${DALORADIUS_ROOT_DIRECTORY}/app/operators>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

<Directory \${DALORADIUS_ROOT_DIRECTORY}>
    Require all denied
</Directory>

ErrorLog \${APACHE_LOG_DIR}/daloradius/operators/error.log
CustomLog \${APACHE_LOG_DIR}/daloradius/operators/access.log combined
</VirtualHost>
EOF

    cat <<EOF > /etc/apache2/sites-available/users.conf
<VirtualHost *:\${DALORADIUS_USERS_PORT}>
ServerAdmin \${DALORADIUS_SERVER_ADMIN}
DocumentRoot \${DALORADIUS_ROOT_DIRECTORY}/app/users

<Directory \${DALORADIUS_ROOT_DIRECTORY}/app/users>
    Options -Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<Directory \${DALORADIUS_ROOT_DIRECTORY}>
    Require all denied
</Directory>

ErrorLog \${APACHE_LOG_DIR}/daloradius/users/error.log
CustomLog \${APACHE_LOG_DIR}/daloradius/users/access.log combined
</VirtualHost>
EOF

    sed -i -e "s/configValues\['CONFIG_DB_HOST'\] = 'localhost';/configValues['CONFIG_DB_HOST'] = '$MYSQL_SERVER';/" \
        -e "s/configValues\['CONFIG_DB_PORT'\] = '3306';/configValues['CONFIG_DB_PORT'] = '$MYSQL_PORT';/" \
        -e "s/configValues\['CONFIG_DB_USER'\] = 'raduser';/configValues['CONFIG_DB_USER'] = '$MYSQL_USER';/" \
        -e "s/configValues\['CONFIG_DB_PASS'\] = 'radpass';/configValues['CONFIG_DB_PASS'] = '$MYSQL_PASSWORD';/" \
        -e "s/configValues\['CONFIG_DB_NAME'\] = 'raddb';/configValues['CONFIG_DB_NAME'] = '$MYSQL_DBNAME';/" \
        /var/www/daloradius/app/common/includes/daloradius.conf.php

    a2dissite 000-default.conf
    a2ensite operators.conf users.conf
    service apache2 reload

    touch /etc/daloradius.lock

else
    echo "Skipping initialization..."
fi

mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2

echo "Starting apache2..."
if [[ ! -d /var/run/apache2 ]] || [[ ! -d /var/lock/apache2 ]] || [[ ! -d /var/log/apache2 ]]; then
    mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2
fi
source /etc/apache2/envvars
apache2 -DFOREGROUND
