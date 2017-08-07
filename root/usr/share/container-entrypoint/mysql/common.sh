#!/bin/bash

export MYSQL_CONFIG="/etc/my.cnf"
export MYSQL_DATADIR="/var/lib/mysql/data/mydata"
export MYSQL_SOCKET="$( mktemp --tmpdir mysql_XXXXXX.sock )"

readonly MYSQL_IDENTIFIER_REGEX='^[a-zA-Z0-9_]+$'
readonly MYSQL_PASSWORD_REGEX='^[a-zA-Z0-9_~!@#$%^&*()-=<>,.?;:|]+$'

function get_secret_mapping() {
    local variable="$1"; shift

    case "${variable}" in
        "MYSQL_ADMIN_PASSWORD" )
            echo mysql/admin_password ;;
        "MYSQL_DATABASE" )
            echo mysql/database ;;
        "MYSQL_PASSWORD" )
            echo mysql/password ;;
        "MYSQL_USER" )
            echo mysql/user ;;
        * )
            echo "${variable}" ;;
    esac
}

function mysql_cleanup_environment() {
    unset MYSQL_ADMIN_PASSWORD \
          MYSQL_DATABASE \
          MYSQL_PASSWORD \
          MYSQL_USER
}

function mysql_cmd() {
    mysql --socket="${MYSQL_SOCKET}" --user=root "$@"
}

function mysql_create_database() {
    local database="$1"; shift

    mysql_cmd <<EOSQL
CREATE DATABASE \`${database}\`;
EOSQL
}

function mysql_create_database_if_not_exists() {
    local database="$1"; shift

    mysql_cmd <<EOSQL
CREATE DATABASE \`${database}\`;
EOSQL
}

function mysql_create_user() {
    local user="$1"; shift

    mysql_cmd <<EOSQL
CREATE USER '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
}

function mysql_create_user_if_not_exists() {
    local user="$1"; shift

    mysql_cmd <<EOSQL
CREATE USER IF NOT EXISTS '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
}

function mysql_drop_database() {
    local database="$1"; shift

    mysql_cmd <<EOSQL
DROP DATABASE IF EXISTS \`${database}\`;
EOSQL
}

function mysql_drop_user() {
    local user="$1"; shift

    if version_lt "${MYSQL_VERSION}" "5.7"; then
        mysql_cmd <<EOSQL
GRANT USAGE ON *.* TO '${user}'@'%';
DROP USER '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
    else
        mysql_cmd <<EOSQL
DROP USER IF EXISTS '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
    fi
}

function mysql_export_config_variables() {
    export MYSQL_FT_MAX_WORD_LEN="${MYSQL_FT_MAX_WORD_LEN:-20}"
    export MYSQL_FT_MIN_WORD_LEN="${MYSQL_FT_MIN_WORD_LEN:-4}"
    export MYSQL_INNODB_USE_NATIVE_AIO="${MYSQL_INNODB_USE_NATIVE_AIO:-1}"
    export MYSQL_LOWER_CASE_TABLE_NAMES="${MYSQL_LOWER_CASE_TABLE_NAMES:-0}"
    export MYSQL_MAX_ALLOWED_PACKET="${MYSQL_MAX_ALLOWED_PACKET:-4M}"
    export MYSQL_MAX_CONNECTIONS="${MYSQL_MAX_CONNECTIONS:-151}"
    export MYSQL_SORT_BUFFER_SIZE="${MYSQL_SORT_BUFFER_SIZE:-256K}"
    export MYSQL_TABLE_OPEN_CACHE="${MYSQL_TABLE_OPEN_CACHE:-2000}"

    local CGROUP_MEMORY_LIMIT_IN_BYTES=$( cgroup_get_memory_limit_in_bytes )

    if [ -n "${CGROUP_MEMORY_LIMIT_IN_BYTES}" ] &&  [ ${CGROUP_MEMORY_LIMIT_IN_BYTES} -gt 0 ]; then
        export MYSQL_INNODB_BUFFER_POOL_SIZE="${MYSQL_INNODB_BUFFER_POOL_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/2 ))M}"
        export MYSQL_INNODB_LOG_BUFFER_SIZE="${MYSQL_INNODB_LOG_BUFFER_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/8 ))M}"
        export MYSQL_INNODB_LOG_FILE_SIZE="${MYSQL_INNODB_LOG_FILE_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/8 ))M}"
        export MYSQL_KEY_BUFFER_SIZE="${MYSQL_KEY_BUFFER_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/10 ))M}"
        export MYSQL_READ_BUFFER_SIZE="${MYSQL_READ_BUFFER_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/20 ))M}"
    else
        export MYSQL_INNODB_BUFFER_POOL_SIZE="${MYSQL_INNODB_BUFFER_POOL_SIZE:-128M}"
        export MYSQL_INNODB_LOG_BUFFER_SIZE="${MYSQL_INNODB_LOG_BUFFER_SIZE:-16M}"
        export MYSQL_INNODB_LOG_FILE_SIZE="${MYSQL_INNODB_LOG_FILE_SIZE:-48M}"
        export MYSQL_KEY_BUFFER_SIZE="${MYSQL_KEY_BUFFER_SIZE:-8M}"
        export MYSQL_READ_BUFFER_SIZE="${MYSQL_READ_BUFFER_SIZE:-128K}"
    fi
}

function mysql_generate_config() {
    envsubst \
        < "${CONTAINER_ENTRYPOINT_PATH}/mysql/my-container.cnf.template" \
        > "${MYSQL_CONFIG}.d/my-container.cnf"

    envsubst \
        < "${CONTAINER_ENTRYPOINT_PATH}/mysql/my-container-tuning.cnf.template" \
        > "${MYSQL_CONFIG}.d/my-container-tuning.cnf"
}

function mysql_grant_privileges() {
    local database="$1"; shift
    local user="$1"; shift

    mysql_cmd <<EOSQL
GRANT ALL ON \`${database}\`.* TO '${user}'@'%';
FLUSH PRIVILEGES;
EOSQL
}

function mysql_initialize() {
    if version_lt "${MYSQL_VERSION}" "5.7"; then
        mysql_install_db --datadir="${MYSQL_DATADIR}" --rpm
    else
        mysqld --datadir="${MYSQL_DATADIR}" --ignore-db-dir=lost+found --initialize-insecure
    fi

    mysql_start_local

    local mysql_user; mysql_user="$( get_value MYSQL_USER '' )"
    if [ -n "${mysql_user}" ]; then
        log_message " ---> Creating user \`${mysql_user}\`"
        mysql_create_user "${mysql_user}"
    fi

    local mysql_database; mysql_database="$( get_value MYSQL_DATABASE '' )"
    if [ -n "${mysql_database}" ]; then
        log_message " ---> Creating database \`${mysql_database}\`"
        mysql_create_database "${mysql_database}"

        if [ -n "${mysql_user}" ]; then
            echo " ---> Granting privileges on \`${mysql_database}\` to \`${mysql_user}\`"
            mysql_grant_privileges "${mysql_database}" "${mysql_user}"
        fi
    fi
}

function mysql_is_initialized() {
    [ -d "${MYSQL_DATADIR}/mysql" ]
}

function mysql_set_password() {
    local user="$1"; shift
    local password="$1"; shift

    mysql_cmd <<EOSQL
SET PASSWORD FOR '${user}'@'%' = PASSWORD('${password}');
EOSQL
}

function mysql_start_local() {
    mysqld --datadir="${MYSQL_DATADIR}" --skip-networking --socket="${MYSQL_SOCKET}" &

    local mysql_pid=$!
    mysql_wait_for_start "${mysql_pid}"
}

function mysql_stop_local() {
    mysqladmin --socket="${MYSQL_SOCKET}" --user=root flush-privileges shutdown
    rm -f "${MYSQL_SOCKET}"
}

function mysql_wait_for_start() {
    local pid="$1" ; shift

    while true; do
        if [ ! -d "/proc/${pid}" ]; then
            exit 1
        fi

        mysqladmin --socket="${MYSQL_SOCKET}" --user=root ping &>/dev/null && return
        log_message " ---> Waiting for MySQL server to start ..."
        sleep 2
    done
}
