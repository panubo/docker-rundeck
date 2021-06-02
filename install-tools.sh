#!/usr/bin/env bash
# shellcheck disable=SC2034

set -euo pipefail
IFS=$'\n\t'

# Do everything from a temp directory
TEMP_DIR="$(mktemp -d)"
finish() {
  rm -rf "${TEMP_DIR}"
}
trap finish EXIT

cd "${TEMP_DIR}"
echo "PWD: $(pwd)"


KUBECTL_1_18_19_CHECKSUM=332820433bc7695801bcf6e8444856fc7daae97fc9261b918d491110d67be116
KUBECTL_1_17_17_CHECKSUM=8329fac94c66bf7a475b630972a8c0b036bab1f28a5584115e8dd26483de8349
KUBECTL_1_16_15_CHECKSUM=e8913069293156ddf55f243814a22d2384fc18b165efb6200606fdeaad146605
KUBECTL_1_15_12_CHECKSUM=a32b762279c33cb8d8f4198f3facdae402248c3164e9b9b664c3afbd5a27472e
KUBECTL_1_14_10_CHECKSUM=7729c6612bec76badc7926a79b26e0d9b06cc312af46dbb80ea7416d1fce0b36
KUBECTL_1_13_12_CHECKSUM=3578dbaec9fd043cf2779fbc54afb4297f3e8b50df7493191313bccbb8046300

HELM_3_5_2_CHECKSUM=01b317c506f8b6ad60b11b1dc3f093276bb703281cb1ae01132752253ec706a2
HELM_3_4_2_CHECKSUM=cacde7768420dd41111a4630e047c231afa01f67e49cc0c6429563e024da4b98
HELM_3_3_4_CHECKSUM=b664632683c36446deeb85c406871590d879491e3de18978b426769e43a1e82c
HELM_3_2_4_CHECKSUM=8eb56cbb7d0da6b73cd8884c6607982d0be8087027b8ded01d6b2759a72e34b1
HELM_3_2_0_CHECKSUM=4c3fd562e64005786ac8f18e7334054a24da34ec04bbd769c206b03b8ed6e457
HELM_3_0_0_CHECKSUM=10e1fdcca263062b1d7b2cb93a924be1ef3dd6c381263d8151dd1a20a3d8c0dc
HELM_2_14_3_CHECKSUM=38614a665859c0f01c9c1d84fa9a5027364f936814d1e47839b05327e400bf55
HELM_2_9_1_CHECKSUM=56ae2d5d08c68d6e7400d462d6ed10c929effac929fedce18d2636a9b4e166ba

SOPS_3_6_1_CHECKSUM=b2252aa00836c72534471e1099fa22fab2133329b62d7826b5ac49511fcc8997

LEGO_4_1_3_CHECKSUM=67007a3a35a488ef6895421954decc6a5bf79b8acd0a66b94df90d88089fd2c5

install_sops() {
  local version checksum checksum_var
  version="${1}"
  checksum_var="SOPS_${version//\./_}_CHECKSUM"
  checksum="${!checksum_var}"

  echo "https://github.com/mozilla/sops/releases/download/v${version}/sops-v${version}.linux"
  echo "${checksum}"

  wget -nv "https://github.com/mozilla/sops/releases/download/v${version}/sops-v${version}.linux"
  echo "${checksum}  sops-v${version}.linux" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum sops-v${version}.linux)"; exit 1; )

  chmod 755 "sops-v${version}.linux"
  chown root:root "sops-v${version}.linux"
  mv "sops-v${version}.linux" /opt/bin/sops
}

install_lego() {
  local version checksum checksum_var
  version="${1}"
  checksum_var="LEGO_${version//\./_}_CHECKSUM"
  checksum="${!checksum_var}"

  echo "https://github.com/xenolf/lego/releases/download/v${version}/lego_v${version}_linux_amd64.tar.gz"
  echo "${checksum}"

  wget -nv "https://github.com/xenolf/lego/releases/download/v${version}/lego_v${version}_linux_amd64.tar.gz"
  echo "${checksum}  lego_v${version}_linux_amd64.tar.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum lego_v${version}_linux_amd64.tar.gz)"; exit 1; )

  tar -zxf "lego_v${version}_linux_amd64.tar.gz" lego
  chmod 755 lego
  chown root:root lego
  mv lego /opt/bin/lego
}

install_helm() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="HELM_${version//\./_}_CHECKSUM"
  checksum="${!checksum_var}"

  IFS='.' read -r -a version_parts <<<"${version}"
  major_minor="${version_parts[0]}.${version_parts[1]}"

    echo "https://get.helm.sh/helm-v${version}-linux-amd64.tar.gz"
    echo "${checksum}"

    wget -nv "https://get.helm.sh/helm-v${version}-linux-amd64.tar.gz"
  echo "${checksum}  helm-v${version}-linux-amd64.tar.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum helm-v${version}-linux-amd64.tar.gz)"; exit 1; )

  tar -zxf "helm-v${version}-linux-amd64.tar.gz" linux-amd64/helm
  chmod 755 linux-amd64/helm
  chown root:root linux-amd64/helm
  mkdir -p "/opt/helm-${major_minor}/bin"
  mv linux-amd64/helm "/opt/helm-${major_minor}/bin/helm"
}

install_kubectl() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="KUBECTL_${version//\./_}_CHECKSUM"
  checksum="${!checksum_var}"

  IFS='.' read -r -a version_parts <<<"${version}"
  major_minor="${version_parts[0]}.${version_parts[1]}"

  echo "https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/linux/amd64/kubectl"
    echo "${checksum}"

  wget -nv "https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/linux/amd64/kubectl"
  echo "${checksum}  kubectl" > SHA256SUM
  sha256sum kubectl
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum kubectl)"; exit 1; )

  chmod 755 kubectl
  chown root:root kubectl
  mkdir -p "/opt/kubectl-${major_minor}/bin"
  mv kubectl "/opt/kubectl-${major_minor}/bin/kubectl"
}

install_sops 3.6.1
install_lego 4.1.3

install_helm 2.9.1
install_helm 2.14.3
install_helm 3.2.4
install_helm 3.3.4
install_helm 3.4.2
install_helm 3.5.2

install_kubectl 1.13.12
install_kubectl 1.14.10
install_kubectl 1.15.12
install_kubectl 1.16.15
install_kubectl 1.17.17
install_kubectl 1.18.19
