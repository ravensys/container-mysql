#!/bin/bash

function ci_case_config_files() {
    local -r TEST_CASE=config_file

    echo " ---> Testing non-default values for configuration options"
    MYSQL_FT_MAX_WORD_LEN=10
    MYSQL_FT_MIN_WORD_LEN=2
    MYSQL_INNODB_BUFFER_POOL_SIZE=64M
    MYSQL_INNODB_LOG_BUFFER_SIZE=8M
    MYSQL_INNODB_LOG_FILE_SIZE=16M
    MYSQL_INNODB_USE_NATIVE_AIO=0
    MYSQL_KEY_BUFFER_SIZE=4M
    MYSQL_LOWER_CASE_TABLE_NAMES=1
    MYSQL_MAX_ALLOWED_PACKET=8M
    MYSQL_MAX_CONNECTIONS=222
    MYSQL_READ_BUFFER_SIZE=256K
    MYSQL_SORT_BUFFER_SIZE=512K
    MYSQL_TABLE_OPEN_CACHE=1111

    ci_mysql_container "${TEST_CASE}_nondefault" testuser testpass \
        -e MYSQL_USER=testuser \
        -e MYSQL_PASSWORD=testpass \
        -e MYSQL_DATABASE=testdb \
        -e MYSQL_FT_MAX_WORD_LEN="${MYSQL_FT_MAX_WORD_LEN}" \
        -e MYSQL_FT_MIN_WORD_LEN="${MYSQL_FT_MIN_WORD_LEN}" \
        -e MYSQL_INNODB_BUFFER_POOL_SIZE="${MYSQL_INNODB_BUFFER_POOL_SIZE}" \
        -e MYSQL_INNODB_LOG_BUFFER_SIZE="${MYSQL_INNODB_LOG_BUFFER_SIZE}" \
        -e MYSQL_INNODB_LOG_FILE_SIZE="${MYSQL_INNODB_LOG_FILE_SIZE}" \
        -e MYSQL_INNODB_USE_NATIVE_AIO="${MYSQL_INNODB_USE_NATIVE_AIO}" \
        -e MYSQL_KEY_BUFFER_SIZE="${MYSQL_KEY_BUFFER_SIZE}" \
        -e MYSQL_LOWER_CASE_TABLE_NAMES="${MYSQL_LOWER_CASE_TABLE_NAMES}" \
        -e MYSQL_MAX_ALLOWED_PACKET="${MYSQL_MAX_ALLOWED_PACKET}" \
        -e MYSQL_MAX_CONNECTIONS="${MYSQL_MAX_CONNECTIONS}" \
        -e MYSQL_READ_BUFFER_SIZE="${MYSQL_READ_BUFFER_SIZE}" \
        -e MYSQL_SORT_BUFFER_SIZE="${MYSQL_SORT_BUFFER_SIZE}" \
        -e MYSQL_TABLE_OPEN_CACHE="${MYSQL_TABLE_OPEN_CACHE}"

    echo " ------> Testing MySQL configuration"
    ci_assert_configuration "${TEST_CASE}_nondefault"


    echo " ---> Testing configuration auto-tuning capabilities"
    ci_mysql_config_defaults
    MYSQL_INNODB_BUFFER_POOL_SIZE=384M
    MYSQL_INNODB_LOG_BUFFER_SIZE=96M
    MYSQL_INNODB_LOG_FILE_SIZE=96M
    MYSQL_KEY_BUFFER_SIZE=76M
    MYSQL_READ_BUFFER_SIZE=38M

    ci_mysql_container "${TEST_CASE}_autotune" testuser testpass \
        -e MYSQL_USER=testuser \
        -e MYSQL_PASSWORD=testpass \
        -e MYSQL_DATABASE=testdb \
        -m 768M

    echo " ------> Testing MySQL configuration"
    ci_assert_configuration "${TEST_CASE}_autotune"
}

function ci_case_config_files_desc() {
    echo "container MySQL configuration files tests"
}
