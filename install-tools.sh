#!/usr/bin/env bash
# shellcheck disable=SC2034

set -euo pipefail
IFS=$'\n\t'

# Do everything from a temp directory
TEMP_DIR="$(mktemp -d)"
finish() {
  rm -rf "${TEMP_DIR}"
  rm -- "$0"
}
trap finish EXIT

cd "${TEMP_DIR}"
echo "PWD: $(pwd)"

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

# Versions

KUBECTL_1_21_2_CHECKSUM=55b982527d76934c2f119e70bf0d69831d3af4985f72bb87cd4924b1c7d528da
KUBECTL_1_20_8_CHECKSUM=9e787c52a52caceeb7cfedafe4d795261dafa5ac1f6fc85ab54701398e454b8e
KUBECTL_1_19_12_CHECKSUM=9a9123b58e3287fdca20db45ab003426d30e7a77ec57605fa25947bc68f6cabf
KUBECTL_1_18_20_CHECKSUM=66a9bb8e9843050340844ca6e72e67632b75b9ebb651559c49db22f35450ed2f
KUBECTL_1_17_17_CHECKSUM=8329fac94c66bf7a475b630972a8c0b036bab1f28a5584115e8dd26483de8349
KUBECTL_1_16_15_CHECKSUM=e8913069293156ddf55f243814a22d2384fc18b165efb6200606fdeaad146605

HELM_3_6_0_CHECKSUM=0a9c80b0f211791d6a9d36022abd0d6fd125139abe6d1dcf4c5bf3bc9dcec9c8
HELM_3_5_2_CHECKSUM=01b317c506f8b6ad60b11b1dc3f093276bb703281cb1ae01132752253ec706a2
HELM_3_4_2_CHECKSUM=cacde7768420dd41111a4630e047c231afa01f67e49cc0c6429563e024da4b98
HELM_3_3_4_CHECKSUM=b664632683c36446deeb85c406871590d879491e3de18978b426769e43a1e82c
HELM_3_2_4_CHECKSUM=8eb56cbb7d0da6b73cd8884c6607982d0be8087027b8ded01d6b2759a72e34b1
HELM_3_2_0_CHECKSUM=4c3fd562e64005786ac8f18e7334054a24da34ec04bbd769c206b03b8ed6e457
HELM_3_0_0_CHECKSUM=10e1fdcca263062b1d7b2cb93a924be1ef3dd6c381263d8151dd1a20a3d8c0dc

SOPS_3_6_1_CHECKSUM=b2252aa00836c72534471e1099fa22fab2133329b62d7826b5ac49511fcc8997

LEGO_4_1_3_CHECKSUM=67007a3a35a488ef6895421954decc6a5bf79b8acd0a66b94df90d88089fd2c5


install_sops 3.6.1

install_lego 4.1.3

install_helm 3.2.4
install_helm 3.3.4
install_helm 3.4.2
install_helm 3.5.2
install_helm 3.6.0

install_kubectl 1.16.15
install_kubectl 1.17.17
install_kubectl 1.18.20
install_kubectl 1.19.12
install_kubectl 1.20.8
install_kubectl 1.21.2

echo "Finished installing tools..."
