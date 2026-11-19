diag() {
  echo "$@" | sed -e 's/^/# /' >&3
}

# From https://github.com/panubo/bash-container/blob/master/functions/wait_http.sh
# This closes fd 3, so call it in a subshell when used from Bats.
wait_http() {
  # Wait for HTTP service to be available
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

# Wait until the Rundeck CLI can talk to the API using the configured token.
wait_rd() {
  local container="${1}"
  local url="${2}"
  local timeout="${3:-60}"

  for (( i=0; i<timeout; i++ )); do
    if docker exec "${container}" env RD_URL="${url}" RD_TOKEN=testtoken rd projects list >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  return 1
}
