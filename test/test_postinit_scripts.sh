#!/bin/bash

function ci_case_postinit_scripts() {
    local -r TEST_CASE=postinit_scripts

    echo " ------> Creating post-initialization volume"
    local postinit_volume; postinit_volume="$( ci_volume_create "${TEST_CASE}_postinit" )"

    echo " ------> Creating post-initialization scripts"
cat > "${postinit_volume}/post-init-test.sh" <<EOF
#!/bin/bash
echo "post-init test successful!" >/var/lib/mysql/post-init-test-success
EOF
cat > "${postinit_volume}/post-init-test" <<EOF
#!/bin/bash
echo "post-init test failed!" >/var/lib/mysql/post-init-test-fail
EOF

    ci_mysql_container "${TEST_CASE}" testuser testpass \
        -e MYSQL_USER=testuser \
        -e MYSQL_PASSWORD=testpass \
        -e MYSQL_DATABASE=testdb \
        -v "${postinit_volume}:/usr/share/container-entrypoint/mysql/post-init.d:Z"

    echo " ------> Testing sourcing of shell script from post-init.d"
    docker exec "$( ci_container_get_cid "${TEST_CASE}" )" \
        bash -c "[ -f /var/lib/mysql/post-init-test-success ] || (echo 'post-init script was not sourced' && exit 1)"

    echo " ------> Testing sourcing of plain text file from post-init.d"
    docker exec "$( ci_container_get_cid "${TEST_CASE}" )" \
        bash -c "[ ! -f /var/lib/mysql/post-init-test-fail ] || (echo 'plain text file in post-init.d directory was sourced' && exit 1)"
}

function ci_case_postinit_scripts_desc() {
    echo "post-initialization scripts sourcing tests"
}
