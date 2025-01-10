#!/usr/bin/env bash
#
# Delay image-triggers sidecar start until Rundeck is up and running

set -e

# wait_http URL [TIMEOUT] [HTTP TIMEOUT]
wait_http() {
  # Wait for http service to be available
  command -v curl >/dev/null 2>&1 || { error "This function requires curl to be installed."; return 1; }
  local url="${1:-'http://localhost'}"
  local timeout="${2:-30}"
  local http_timeout="${3:-2}"
  echo -n "Connecting to HTTP at ${url}"
  for (( i=0;; i++ )); do
    if [[ "${i}" -eq "${timeout}" ]]; then
      echo " timeout!"
      return 99
    fi
    sleep 1
    (curl --max-time "${http_timeout}" "${url}") &>/dev/null && break
    echo -n "."
  done
  echo " connected."
  exec 3>&-
  exec 3<&-
}

wait_http "${RD_URL}" 300

echo ">> Starting image-triggers"
exec /usr/local/bin/image-triggers "$@"
