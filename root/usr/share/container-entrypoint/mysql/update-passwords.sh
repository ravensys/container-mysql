#!/bin/bash

function mysql_update_passwords() {
    local mysql_user; mysql_user="$( get_value MYSQL_USER '' )"
    local mysql_password; mysql_password="$( get_value MYSQL_PASSWORD '' )"
    if [ -n "${mysql_password}" ]; then
        mysql_set_password "${mysql_user}" "${mysql_password}"
    fi

    local mysql_admin_password; mysql_admin_password="$( get_value MYSQL_ADMIN_PASSWORD '' )"
    if [ -n "${mysql_admin_password}" ]; then
        if [[ "${MYSQL_VERSION}" > "5.6" ]]; then
            mysql_create_user_if_not_exists root
        fi
        mysql_cmd <<EOSQL
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${mysql_admin_password}' WITH GRANT OPTION;
EOSQL
    elif [ "root" != "${mysql_user}" ]; then
        mysql_drop_user root
    fi
}

mysql_update_passwords
