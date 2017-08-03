#!/bin/bash

[ -n "${TESTDIR:-}" ] || \
    ( echo "Test suite source directory is not set!" && exit 1 )
[ -n "${COMMONDIR:-}" ] || \
    ( echo "Common tests source directory is not set!" && exit 1 )

function ci_volume_set_permissions() {
    local volume_dir="$1"; shift

    setfacl -m u:27:rwx "${volume_dir}"
}

function ci_mysql_build_envs() {
    local docker_args

    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        docker_args+=" -e MYSQL_ADMIN_PASSWORD=${TEST_ADMIN_PASSWORD}"
    fi

    if [ -n "${TEST_USER:-}" ]; then
        docker_args+=" -e MYSQL_USER=${TEST_USER}"
    fi

    if [ -n "${TEST_PASSWORD:-}" ]; then
        docker_args+=" -e MYSQL_PASSWORD=${TEST_PASSWORD}"
    fi

    docker_args+=" -e MYSQL_DATABASE=testdb"

    echo "${docker_args}"
}

function ci_mysql_build_secrets() {
    local secrets_volume="$1"; shift
    local secrets_prefix="${1:-mysql/}"
    local docker_args=" -v ${secrets_volume}:/run/secrets"

    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}admin_password" "${TEST_ADMIN_PASSWORD}"
        [ "mysql/" == "${secrets_prefix}" ] || \
            docker_args+=" -e MYSQL_ADMIN_PASSWORD_SECRET=${secrets_prefix}admin_password"
    fi

    if [ -n "${TEST_USER:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}user" "${TEST_USER}"
        [ "mysql/" == "${secrets_prefix}" ] || \
            docker_args+=" -e MYSQL_USER_SECRET=${secrets_prefix}user"
    fi

    if [ -n "${TEST_PASSWORD:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}password" "${TEST_PASSWORD}"
        [ "mysql/" == "${secrets_prefix}" ] || \
            docker_args+=" -e MYSQL_PASSWORD_SECRET=${secrets_prefix}password"
    fi

    ci_secret_create "${secrets_volume}" "${secrets_prefix}database" testdb
    [ "mysql/" == "${secrets_prefix}" ] || \
        docker_args+=" -e MYSQL_DATABASE_SECRET=${secrets_prefix}database"

    echo "${docker_args}"
}

function ci_mysql_cmd() {
    local ip="$1"; shift
    local user="$1"; shift
    local password="$1"; shift

    docker run --rm "${IMAGE_NAME}" \
        mysql --host "${ip}" -u"${user}" -p"${password}" "$@" testdb
}

function ci_mysql_config_defaults() {
    MYSQL_FT_MAX_WORD_LEN=20
    MYSQL_FT_MIN_WORD_LEN=4
    MYSQL_INNODB_BUFFER_POOL_SIZE=128M
    MYSQL_INNODB_LOG_BUFFER_SIZE=16M
    MYSQL_INNODB_LOG_FILE_SIZE=48M
    MYSQL_INNODB_USE_NATIVE_AIO=1
    MYSQL_KEY_BUFFER_SIZE=8M
    MYSQL_LOWER_CASE_TABLE_NAMES=0
    MYSQL_MAX_ALLOWED_PACKET=4M
    MYSQL_MAX_CONNECTIONS=151
    MYSQL_READ_BUFFER_SIZE=128K
    MYSQL_SORT_BUFFER_SIZE=256K
    MYSQL_TABLE_OPEN_CACHE=2000
}

function ci_mysql_container() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift

    echo " ------> Creating MySQL container [ ${container} ]"
    ci_container_create "${container}" "$@"

    echo " ------> Verifying initial connection to container as ${user}(${password})"
    ci_mysql_wait_connection "${container}" "${user}" "${password}"
}

function ci_mysql_wait_connection() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift
    local max_attempts="${1:-20}"

    local i
    local container_ip; container_ip="$( ci_container_get_ip "${container}" )"
    for i in $( seq ${max_attempts} ); do
        echo " ------> Connection attempt to container [ ${container} ] < ${i} / ${max_attempts} >"
        if ci_mysql_cmd "${container_ip}" "${user}" "${password}" <<< "SELECT 1;"; then
            return
        fi
        sleep 2
    done

    exit 1
}

function ci_assert_config_option() {
    local container="$1"; shift
    local option_name="$1"; shift
    local option_value="$1"; shift

    docker exec $( ci_container_get_cid "${container}" ) \
        bash -c "grep -qx '${option_name} = ${option_value}' /etc/my.cnf.d/*.cnf"
}

function ci_assert_configuration() {
    local container="$1"; shift

    ci_assert_config_option "${container}" ft_max_word_len "${MYSQL_FT_MAX_WORD_LEN}"
    ci_assert_config_option "${container}" ft_min_word_len "${MYSQL_FT_MIN_WORD_LEN}"
    ci_assert_config_option "${container}" innodb_buffer_pool_size "${MYSQL_INNODB_BUFFER_POOL_SIZE}"
    ci_assert_config_option "${container}" innodb_log_buffer_size "${MYSQL_INNODB_LOG_BUFFER_SIZE}"
    ci_assert_config_option "${container}" innodb_log_file_size "${MYSQL_INNODB_LOG_FILE_SIZE}"
    ci_assert_config_option "${container}" innodb_use_native_aio "${MYSQL_INNODB_USE_NATIVE_AIO}"
    ci_assert_config_option "${container}" key_buffer_size "${MYSQL_KEY_BUFFER_SIZE}"
    ci_assert_config_option "${container}" lower_case_table_names "${MYSQL_LOWER_CASE_TABLE_NAMES}"
    ci_assert_config_option "${container}" max_allowed_packet "${MYSQL_MAX_ALLOWED_PACKET}"
    ci_assert_config_option "${container}" max_connections "${MYSQL_MAX_CONNECTIONS}"
    ci_assert_config_option "${container}" read_buffer_size "${MYSQL_READ_BUFFER_SIZE}"
    ci_assert_config_option "${container}" sort_buffer_size "${MYSQL_SORT_BUFFER_SIZE}"
    ci_assert_config_option "${container}" table_open_cache "${MYSQL_TABLE_OPEN_CACHE}"
}

function ci_assert_container_fails() {
    local ret=0
    timeout -s 9 --preserve-status 60s docker run --rm "$@" "${IMAGE_NAME}" || ret=$?

    [ ${ret} -lt 100 ] || \
        exit 1
}

function ci_assert_local_access() {
    local container="$1"; shift

    docker exec $( ci_container_get_cid "${container}" ) \
        bash -c 'mysql -uroot <<< "SELECT 1;"'
}

function ci_assert_login_access() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift
    local success="$1"; shift

    if ci_mysql_cmd $( ci_container_get_ip "${container}" ) "${user}" "${password}" <<< "SELECT 1;"; then
        if $success; then
            echo "${user}(${password}) access granted as expected."
            return
        fi
    else
        if ! $success; then
            echo "${user}(${password}) access denied as expected."
            return
        fi
    fi

    echo "${user}(${password}) login assertion failed."
    exit 1
}

function ci_assert_mysql() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift

    local container_ip; container_ip="$( ci_container_get_ip "${container}" )"
    ci_mysql_cmd "${container_ip}" "${user}" "${password}" <<< "CREATE TABLE testtbl (testcol1 VARCHAR(20), testcol2 VARCHAR(20));"
    ci_mysql_cmd "${container_ip}" "${user}" "${password}" <<< "INSERT INTO testtbl VALUES('foo1', 'bar1');"
    ci_mysql_cmd "${container_ip}" "${user}" "${password}" <<< "INSERT INTO testtbl VALUES('foo2', 'bar2');"
    ci_mysql_cmd "${container_ip}" "${user}" "${password}" <<< "SELECT * FROM testtbl;"
    ci_mysql_cmd "${container_ip}" "${user}" "${password}" <<< "DROP TABLE testtbl;"
}
