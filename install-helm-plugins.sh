#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

helm_version="3.18"

export PATH=/opt/helm-${helm_version}/bin:$HOME/bin:$PATH

# plugins_dir="$(helm env | sed -E -e '/HELM_PLUGINS/!d' -e 's/^[^=]+="(.*)"$/\1/')"

set -x

helm env

helm plugin install https://github.com/databus23/helm-diff --version 3.12.4
helm plugin install https://github.com/jkroepke/helm-secrets --version 4.6.5
