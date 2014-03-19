ldumbd
======

A simple, self-contained LDAP server with a database back end.

Documentation
-------------

Ldumbd is a simple, self-contained read-only LDAP server that uses PostgreSQL, MySQL/MariaDB or SQLite as a back end.

Ldumbd is designed primarily to act as an LDAP gateway to a simple SQL user database for use with the `nss-pam-ldapd` Name Service Switch (NSS) module.

Limitations
-----------

At the moment, ldumbd has no support for any of the following:

 - LDAP schemas
 - LDAP binds
 - any request type other than search requests
 - "approximately equal" operators in search filters

Installation: Debian Wheezy
---------------------------

    sudo -i
    export LDUMBD_DIR=/var/lib/ldumbd
    mkdir -p ${LDUMBD_DIR}
    groupadd -r ldumbd
    useradd -r -s /bin/false -g ldumbd -d ${LDUMBD_DIR} ldumbd
    chown ldumbd:ldumbd ${LDUMBD_DIR}
    chmod 700 ${LDUMBD_DIR}
    aptitude install libsqlite3-dev
    gem install ldumbd
    export MIGRATIONS=$(dirname $(gem contents ldumbd | grep migrations/001))

Database setup: SQLite
----------------------

    sudo -u ldumbd sequel -m ${MIGRATIONS} sqlite://${LDUMBD_DIR}/ldumbd.sqlite3

Database setup: PostgreSQL
--------------------------

    aptitude install postgresql libpq-dev libsqlite3-dev
    sudo -u postgres createuser ldumbd
    sudo -u postgres createdb -O ldumbd ldumbd
    gem install pg
    sudo -u ldumbd sequel -m ${MIGRATIONS} postgres:///ldumbd

Database setup: MySQL/MariaDB
-----------------------------

    export DB_PASSWORD='secret'
    aptitude install mysql-server libmysqlclient-dev libsqlite3-dev
    cat <<EOS | mysql -u root -p
    CREATE DATABASE ldumbd;
    CREATE USER 'ldumbd'@'localhost' IDENTIFIED BY 'secret';
    GRANT ALL PRIVILEGES ON ldumbd.* TO 'ldumbd'@'localhost';
    EOS
    gem install mysql2
    sequel -m ${MIGRATIONS} "mysql2://ldumbd:${DB_PASSWORD}@localhost/ldumbd"

Running ldumbd
--------------

    cp ${LDUMBD_DIR}/config.yml.sample /etc/ldumbd.yml
    $EDITOR /etc/ldumbd.yml
    ldumbd /etc/ldumbd.yml

Copyright
---------

Copyright (c) 2014 Sebastian Boehm. See LICENSE for details.
