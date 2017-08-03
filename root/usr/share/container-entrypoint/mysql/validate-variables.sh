#!/bin/bash

function mysql_usage() {
    [ $# -eq 1 ] && echo "$1" >&2

    cat >&2 <<EOHELP

MySQL SQL database server Docker image

Environment variables (container initialization):
  MYSQL_ADMIN_PASSWORD  Password for the admin \`root\` account
  MYSQL_DATABASE        Name of database to be created
  MYSQL_PASSWORD        Password for the user account
  MYSQL_USER            Name of user to be created

Environment variables (mysql configuration):

  MYSQL_FT_MAX_WORD_LEN
  MYSQL_FT_MIN_WORD_LEN
  MYSQL_INNODB_BUFFER_POOL_SIZE
  MYSQL_INNODB_LOG_BUFFER_SIZE
  MYSQL_INNODB_LOG_FILE_SIZE
  MYSQL_INNODB_USE_NATIVE_AIO
  MYSQL_KEY_BUFFER_SIZE
  MYSQL_LOWER_CASE_TABLE_NAMES
  MYSQL_MAX_ALLOWED_PACKET
  MYSQL_MAX_CONNECTIONS
  MYSQL_READ_BUFFER_SIZE
  MYSQL_SORT_BUFFER_SIZE
  MYSQL_TABLE_OPEN_CACHE

Secrets:
  mysql/admin_password  Password for the admin \`root\` account
                        (environment variable: MYSQL_ADMIN_PASSWORD_SECRET)
  mysql/database        Name of database to be created
                        (environment variable: MYSQL_DATABASE_SECRET)
  mysql/password        Password for the user account
                        (environment variable: MYSQL_PASSWORD_SECRET)
  mysql/user            Name of user to be created
                        (environment variable: MYSQL_USER_SECRET)

Volumes:
  /var/lib/mysql/data   MySQL data directory

For more information see /usr/share/container-scripts/mysql/README.md within container
or visit <https://github.com/ravensys/container-mysql>.
EOHELP

    exit 1
}

function myql_validate_variables() {
    local user_specified=0
    local root_specified=0

    local mysql_admin_password; mysql_admin_password="$( get_value MYSQL_ADMIN_PASSWORD '' )"
    local mysql_database; mysql_database="$( get_value MYSQL_DATABASE '' )"
    local mysql_password; mysql_password="$( get_value MYSQL_PASSWORD '' )"
    local myql_user; myql_user="$( get_value MYSQL_USER '' )"

    if [ -n "${myql_user}" ] || [ -n "${mysql_password}" ]; then
        [[ "${myql_user}" =~ ${MYSQL_IDENTIFIER_REGEX} ]] || \
            mysql_usage "Invalid MySQL user (invalid character or empty)."

        [ ${#myql_user} -le 16 ] || \
            mysql_usage "Invalid MySQL user (too long, max. 16 characters)."

        [[ "${mysql_password:-}" =~ ${MYSQL_PASSWORD_REGEX} ]] || \
            mysql_usage "Invalid MySQL password (invalid character or empty)."

        user_specified=1
    fi

    if [ -n "${mysql_admin_password}" ]; then
        [[ "${mysql_admin_password}" =~ ${MYSQL_PASSWORD_REGEX} ]] || \
            mysql_usage "Invalid MySQL admin password (invalid character or empty)."

        root_specified=1
    fi

    if [ ${user_specified} -eq 1 ] && [ "root" == "${myql_user}" ]; then
        [ ${root_specified} -eq 0 ] || \
            mysql_usage "When MYSQL_USER is set to 'root' admin password must be set only in MYSQL_PASSWORD."

        user_specified=0
        root_specified=1
    fi

    [ ${user_specified} -eq 1 ] || [ ${root_specified} -eq 1 ] || \
        mysql_usage

    [ ${root_specified} -eq 0 ] && [ -z "${mysql_database}" ] && \
        mysql_usage

    if [ -n "${mysql_database}" ]; then
        [[ "${mysql_database}" =~ ${MYSQL_IDENTIFIER_REGEX} ]] || \
            mysql_usage "Invalid MySQL database name (invalid character or empty)."

        [ ${#mysql_database} -le 64 ] || \
            mysql_usage "Invalid MySQL database name (too long, max. 64 characters)."
    fi
}

myql_validate_variables
