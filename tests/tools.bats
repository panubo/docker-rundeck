load setup.bash

@test "sops" {
  run docker run --rm --entrypoint /opt/bin/sops "${IMAGE}" --version
  assert_success
  assert_line --regexp '^sops [0-9]+\.[0-9]+\.[0-9]+'
}

@test "lego" {
  run docker run --rm --entrypoint /opt/bin/lego "${IMAGE}" --version
  assert_success
  assert_line --regexp '^lego version [0-9]+\.[0-9]+\.[0-9]+'
}

@test "yq" {
  run docker run --rm --entrypoint /opt/bin/yq "${IMAGE}" --version
  assert_success
  assert_line --regexp '^yq .* version v[0-9]+\.[0-9]+\.[0-9]+'
}

@test "oras" {
  run docker run --rm --entrypoint /opt/bin/oras "${IMAGE}" version
  assert_success
  assert_line --regexp '^Version:[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+'
}

@test "crane" {
  run docker run --rm --entrypoint /opt/bin/crane "${IMAGE}" version
  assert_success
  assert_line --regexp '^[0-9]+\.[0-9]+\.[0-9]+$'
}

@test "argocd" {
  run docker run --rm --entrypoint /opt/bin/argocd "${IMAGE}" version --client
  assert_success
  assert_line --regexp '^argocd: v[0-9]+\.[0-9]+\.[0-9]+'
}

@test "helm versions" {
  run docker run --rm --entrypoint /bin/bash "${IMAGE}" -c 'for helm in /opt/helm-*/bin/helm; do "$helm" version; done'
  assert_success
  assert_line --regexp 'Version:"v3\.18\.[0-9]+"'
  assert_line --regexp 'Version:"v3\.19\.[0-9]+"'
}

@test "helm plugins" {
  run docker run --rm --entrypoint /bin/bash "${IMAGE}" -c 'helm="$(ls -d /opt/helm-*/bin/helm | sort -V | head -1)"; "$helm" plugin list'
  assert_success
  assert_line --regexp '^diff[[:space:]]'
  assert_line --regexp '^secrets[[:space:]]'
}

@test "kubectl versions" {
  run docker run --rm --entrypoint /bin/bash "${IMAGE}" -c 'for kubectl in /opt/kubectl-*/bin/kubectl; do "$kubectl" version --client; done'
  assert_success
  assert_line --regexp '^Client Version: v1\.34\.[0-9]+'
  assert_line --regexp '^Client Version: v1\.35\.[0-9]+'
  assert_line --regexp '^Client Version: v1\.36\.[0-9]+'
}

@test "argo versions" {
  run docker run --rm --entrypoint /bin/bash "${IMAGE}" -c 'for argo in /opt/argo-*/bin/argo; do "$argo" version; done'
  assert_success
  assert_line --regexp '^argo: v3\.4\.[0-9]+'
  assert_line --regexp '^argo: v3\.6\.[0-9]+'
  assert_line --regexp '^argo: v3\.7\.[0-9]+'
}

@test "aws cli" {
  run docker run --rm --entrypoint aws "${IMAGE}" --version
  assert_success
  assert_line --regexp '^aws-cli/[0-9]+\.[0-9]+\.[0-9]+'
}

@test "gcloud" {
  run docker run --rm --entrypoint gcloud "${IMAGE}" --version
  assert_success
  assert_line --regexp '^Google Cloud SDK [0-9]+\.[0-9]+\.[0-9]+'
}

@test "ansible" {
  run docker run --rm --entrypoint ansible "${IMAGE}" --version
  assert_success
  assert_line --regexp '^ansible \[core [0-9]+\.[0-9]+\.[0-9]+\]'
}

@test "apprise" {
  run docker run --rm --entrypoint apprise "${IMAGE}" --version
  assert_success
  assert_line --regexp '^Apprise v[0-9]+\.[0-9]+\.[0-9]+'
}

@test "rundeck cli" {
  run docker run --rm --entrypoint rd "${IMAGE}" --version
  assert_success
  assert_line --regexp '^[0-9]+\.[0-9]+\.[0-9]+$'
}

@test "dumb-init" {
  run docker run --rm --entrypoint dumb-init "${IMAGE}" --version
  assert_success
  assert_line --regexp '^dumb-init v[0-9]+\.[0-9]+\.[0-9]+$'
}

@test "java" {
  run docker run --rm --entrypoint java "${IMAGE}" -version
  assert_success
  assert_line --regexp '^openjdk version "17\.'
  assert_output --partial 'Zulu'
}

@test "h2 shell" {
  run docker run --rm --entrypoint /bin/bash "${IMAGE}" -c 'java -cp /opt/bin/h2.jar org.h2.tools.Shell -help'
  assert_success
  assert_output --partial 'Interactive command line tool to access a database using JDBC.'
}

@test "k8s sidecar" {
  run docker run --rm --entrypoint python3 "${IMAGE}" /sidecar/sidecar.py --help
  assert_success
  assert_output --partial 'CLI flags for kiwigrid sidecar'
}

@test "image-triggers" {
  run docker run --rm --entrypoint /usr/local/bin/image-triggers "${IMAGE}" --help
  assert_success
  assert_output --partial 'Usage of /usr/local/bin/image-triggers'
}

@test "entrypoint scripts" {
  run docker run --rm --entrypoint /bin/bash "${IMAGE}" -c 'for script in /run.sh /sidecar.sh /triggers.sh /run-h2-v2-migration.sh; do test -x "${script}" && bash -n "${script}" || exit 1; done'
  assert_success
}
