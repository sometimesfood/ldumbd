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

Installation: Debian + SQLite
-----------------------------

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
    sudo -u ldumbd sequel -m ${MIGRATIONS} sqlite://${LDUMBD_DIR}/ldumbd.sqlite3

Installation: Debian + PostgreSQL
---------------------------------

    sudo -i
    export LDUMBD_DIR=/var/lib/ldumbd
    mkdir -p ${LDUMBD_DIR}
    groupadd -r ldumbd
    useradd -r -s /bin/false -g ldumbd -d ${LDUMBD_DIR} ldumbd
    chown ldumbd:ldumbd ${LDUMBD_DIR}
    chmod 700 ${LDUMBD_DIR}
    aptitude install postgresql libpq-dev libsqlite3-dev
    sudo -u postgres createuser ldumbd
    sudo -u postgres createdb -O ldumbd ldumbd
    gem install pg ldumbd
    sudo -u ldumbd sequel -m ${MIGRATIONS} postgres:///ldumbd

Installation: Debian + MySQL/MariaDB
------------------------------------

    sudo -i
    groupadd -r ldumbd
    useradd -r -s /bin/false -g ldumbd -d /var/lib/ldumbd ldumbd
    mkdir -p /var/lib/ldumbd
    chown ldumbd:ldumbd /var/lib/ldumbd
    chmod 700 /var/lib/ldumbd
    aptitude install mysql-server libmysqlclient-dev libsqlite3-dev
    cat <<EOS | mysql -u root -p
    CREATE DATABASE ldumbd;
    CREATE USER 'ldumbd'@'localhost' IDENTIFIED BY 'secret';
    GRANT ALL PRIVILEGES ON ldumbd.* TO 'ldumbd'@'localhost';
    EOS
    gem install mysql2 ldumbd
    sequel -m ${MIGRATIONS} "mysql2://ldumbd:secret@localhost/ldumbd"

Copyright
---------

Copyright (c) 2014 Sebastian Boehm. See LICENSE for details.
