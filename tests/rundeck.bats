load functions.bash
load setup.bash

setup_file() {
  # These tests share a single Rundeck container, so run them serially.
  export BATS_NO_PARALLELIZE_WITHIN_FILE=true

  repo_root="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  export repo_root

  volume_prefix="rundeck-test-$(uuidgen)"
  export volume_prefix

  for volume in data var logs home rundeck log; do
    docker volume create "${volume_prefix}-${volume}" >/dev/null
  done

  if ! container="$(docker run -d \
    --name "${volume_prefix}" \
    -p 4440 \
    -e RD_URL=http://localhost:4440 \
    -v "${repo_root}/tests/fixtures/config:/config:ro,Z" \
    -v "${repo_root}/tests/fixtures:/fixtures:ro,Z" \
    -v "${volume_prefix}-data:/var/lib/rundeck/data" \
    -v "${volume_prefix}-var:/var/lib/rundeck/var" \
    -v "${volume_prefix}-logs:/var/lib/rundeck/logs" \
    -v "${volume_prefix}-home:/home/rundeck" \
    -v "${volume_prefix}-rundeck:/var/rundeck" \
    -v "${volume_prefix}-log:/var/log/rundeck" \
    "${IMAGE}")"; then
    return 1
  fi
  export container

  host_port="$(docker inspect --format '{{(index (index .NetworkSettings.Ports "4440/tcp") 0).HostPort}}' "${container}")"
  export host_port

  # Wait for Rundeck to be listening, then wait until the API and CLI are usable.
  if ! ( wait_http "http://127.0.0.1:${host_port}/api/54/metrics/ping" 300 ); then
    docker logs "${container}" >&3 2>&3 || true
    return 1
  fi

  if ! wait_rd "${container}" http://localhost:4440 60; then
    docker logs "${container}" >&3 2>&3 || true
    return 1
  fi
}

teardown_file() {
  if [[ -n "${container:-}" ]]; then
    docker rm -f "${container}" >/dev/null 2>&1 || true
  fi

  if [[ -n "${volume_prefix:-}" ]]; then
    for volume in data var logs home rundeck log; do
      docker volume rm -f "${volume_prefix}-${volume}" >/dev/null 2>&1 || true
    done
  fi
}

@test "rundeck configuration is generated" {
  run docker exec "${container}" grep -q '^grails.serverURL=http://localhost:4440$' /etc/rundeck/rundeck-config.properties
  assert_success

  run docker exec "${container}" grep -q '^rundeck.api.tokens.duration.max=30d$' /etc/rundeck/rundeck-config.properties
  assert_success

  run docker exec "${container}" grep -q '^rundeck.tokens.file=/etc/rundeck/tokens.properties$' /etc/rundeck/framework.properties
  assert_success
}

@test "authentication tokens are generated" {
  run docker exec "${container}" grep -q '^apiadmin: testtoken, admin$' /etc/rundeck/tokens.properties
  assert_success

  run docker exec "${container}" grep -q '^configuresh: [A-Za-z0-9]*, admin$' /etc/rundeck/tokens.properties
  assert_success
}

@test "PAM users are configured" {
  run docker exec "${container}" grep -q '^admin1:-,user,admin$' /etc/rundeck/realm.properties
  assert_success

  run docker exec "${container}" grep -q '^user1:-,user$' /etc/rundeck/realm.properties
  assert_success

  run docker exec "${container}" test -f /etc/rundeck_passwd.db
  assert_success

  run docker exec "${container}" grep -q 'pam_userdb.so' /etc/pam.d/rundeck
  assert_success
}

@test "bootstrap scripts and SSH key are generated" {
  for script in configure.sh export_jobs.sh trigger_rundeck_job.sh trigger_registry_rules.sh; do
    run docker exec "${container}" test -x "/scripts/${script}"
    assert_success
  done

  run docker exec "${container}" test -f /home/rundeck/.ssh/id_rsa
  assert_success

  run docker exec "${container}" test -f /home/rundeck/.ssh/id_rsa.pub
  assert_success

  run docker exec "${container}" grep -q '^github.com ' /home/rundeck/.ssh/known_hosts
  assert_success
}

@test "runtime directories have the correct permissions" {
  run docker exec "${container}" stat -c '%a %U:%G %n' \
    /var/lib/rundeck/data \
    /var/lib/rundeck/logs \
    /var/lib/rundeck/var \
    /var/rundeck \
    /home/rundeck \
    /var/log/rundeck
  assert_success

  assert_line --partial '750 rundeck:rundeck /var/lib/rundeck/data'
  assert_line --partial '750 rundeck:rundeck /var/lib/rundeck/logs'
  assert_line --partial '750 rundeck:rundeck /var/lib/rundeck/var'
  assert_line --partial '755 rundeck:rundeck /var/rundeck'
  assert_line --partial '755 rundeck:rundeck /home/rundeck'
  assert_line --partial '6775 rundeck:rundeck /var/log/rundeck'
}

@test "web interface is available" {
  run curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${host_port}/"
  assert_success
  assert_output '302'

  run curl -sSf "http://127.0.0.1:${host_port}/user/login"
  assert_success
  assert_output --partial 'Rundeck'
}

@test "API requires authentication" {
  run curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${host_port}/api/54/projects"
  assert_success
  assert_output '403'
}

@test "API token authentication works" {
  run curl -sSf -H 'X-Rundeck-Auth-Token: testtoken' "http://127.0.0.1:${host_port}/api/54/metrics/ping"
  assert_success
  assert_output 'pong'
}

@test "system info API returns a version" {
  run curl -sSf -H 'X-Rundeck-Auth-Token: testtoken' "http://127.0.0.1:${host_port}/api/54/system/info"
  assert_success
  assert_output --regexp '"version":"[0-9]+\.[0-9]+\.[0-9]+[^"]*"'
}

@test "PAM authentication works" {
  run docker exec "${container}" env RD_URL=http://localhost:4440 RD_USER=admin1 RD_PASSWORD=admin1 rd projects list
  assert_success
  assert_output --partial 'Projects'

  run docker exec "${container}" env RD_URL=http://localhost:4440 RD_USER=admin1 RD_PASSWORD=wrong rd projects list
  assert_failure
  assert_output --partial 'Password Authentication failed'
}

@test "create test objects and run a job" {
  run docker exec "${container}" /fixtures/create-test-objects.sh
  assert_success

  run docker exec "${container}" env RD_URL=http://localhost:4440 RD_TOKEN=testtoken rd projects list
  assert_success
  assert_output --partial 'TestProject'

  run docker exec "${container}" env RD_URL=http://localhost:4440 RD_TOKEN=testtoken rd jobs list -p TestProject
  assert_success
  assert_output --partial 'Job1'
}
