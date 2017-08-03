#!/bin/bash

# |  USER  |  PASS  |  DB  |  ADMIN  |  VALID  |
# | :----- | :----- | :--- | :------ | :------ |
# |  -     |  -     |  -   |  -      |  -      |
# |  -     |  -     |  -   |  +      |  +      |
# |  -     |  -     |  +   |  -      |  -      |
# |  -     |  -     |  +   |  +      |  +      |
# |  -     |  +     |  -   |  -      |  -      |
# |  -     |  +     |  -   |  +      |  -      |
# |  -     |  +     |  +   |  -      |  -      |
# |  -     |  +     |  +   |  +      |  -      |
# |  +     |  -     |  -   |  -      |  -      |
# |  +     |  -     |  -   |  +      |  -      |
# |  +     |  -     |  +   |  -      |  -      |
# |  +     |  -     |  +   |  +      |  -      |
# |  +     |  +     |  -   |  -      |  -      |
# |  +     |  +     |  -   |  +      |  +      |
# |  +     |  +     |  +   |  -      |  +      |
# |  +     |  +     |  +   |  +      |  +      |

function ci_case_entrypoint_validations() {
    local -r TEST_CASE=entrypoint_validations

    echo " ---> Testing invalid environment variable combinations"

    echo " ------> No environment variable set"
    ci_assert_container_fails

    echo " ------> Set environment variables: MYSQL_DATABASE"
    ci_assert_container_fails \
        -e MYSQL_DATABASE=db

    echo " ------> Set environment variables: MYSQL_PASSWORD"
    ci_assert_container_fails \
        -e MYSQL_PASSWORD=pass

    echo " ------> Set environment variables: MYSQL_PASSWORD, MYSQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MYSQL_PASSWORD, MYSQL_DATABASE"
    ci_assert_container_fails \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE=db

    echo " ------> Set environment variables: MYSQL_PASSWORD, MYSQL_DATABASE, MYSQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE=db \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MYSQL_USER"
    ci_assert_container_fails \
        -e MYSQL_USER=user

    echo " ------> Set environment variables: MYSQL_USER, MYSQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MYSQL_USER, MYSQL_DATABASE"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_DATABASE=db

    echo " ------> Set environment variables: MYSQL_USER, MYSQL_DATABASE, MYSQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_DATABASE=db \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: MYSQL_USER, MYSQL_PASSWORD"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_PASSWORD=pass

    echo " ------> Set environment variables: MYSQL_USER(root), MYSQL_PASSWORD, MYSQL_DATABASE, MYSQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e MYSQL_USER=root \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE=db \
        -e MYSQL_ADMIN_PASSWORD=adminpass


    echo " ---> Testing invalid environment variable values"
    local VERY_LONG_IDENTIFIER="very_long_identifier_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

    echo " ------> [ MYSQL_USER ] Invalid character"
    ci_assert_container_fails \
        -e MYSQL_USER=\$invalid \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE=db \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ MYSQL_USER ] Too long"
    ci_assert_container_fails \
        -e MYSQL_USER=very_long_user_xx \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE=db \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ MYSQL_PASSWORD ] Invalid character"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_PASSWORD="\"" \
        -e MYSQL_DATABASE=db \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ MYSQL_DATABASE ] Invalid character"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE=\$invalid \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ MYSQL_DATABASE ] Too long"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE="${VERY_LONG_IDENTIFIER}" \
        -e MYSQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ MYSQL_ADMIN_PASSWORD ] Invalid character"
    ci_assert_container_fails \
        -e MYSQL_USER=user \
        -e MYSQL_PASSWORD=pass \
        -e MYSQL_DATABASE=db \
        -e MYSQL_ADMIN_PASSWORD="\""
}

function ci_case_entrypoint_validations_desc() {
    echo "container entrypoint validations tests"
}
