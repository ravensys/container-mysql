#!/bin/bash

function ci_case_secrets_priority() {
    local -r TEST_CASE=secrets_priority

    echo " ------> Creating docker secrets volume"
    local secrets_volume; secrets_volume="$( ci_volume_create "${TEST_CASE}_secrets" )"

    echo " ------> Creating docker secrets (simulation)"
    ci_secret_create "${secrets_volume}" mysql/user secretuser
    ci_secret_create "${secrets_volume}" mysql/password secretpass
    ci_secret_create "${secrets_volume}" mysql/database testdb

    ci_mysql_container "${TEST_CASE}" secretuser secretpass \
        -e MYSQL_USER=testuser \
        -e MYSQL_PASSWORD=testpass \
        -e MYSQL_DATABASE=testdb \
        -v "${secrets_volume}:/run/secrets:Z"

    echo " -------> Testing connection to container (with credentials set in environment variables)"
    ci_assert_login_access "${TEST_CASE}" testuser testpass false
}

function ci_case_secrets_priority_desc() {
    echo "docker secrets priority (over environment variables) tests"
}
