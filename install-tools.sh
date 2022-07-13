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

install_argo() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="ARGO_${version//\./_}_CHECKSUM"
  checksum="${!checksum_var}"

  IFS='.' read -r -a version_parts <<<"${version}"
  major_minor="${version_parts[0]}.${version_parts[1]}"

  echo "https://github.com/argoproj/argo-workflows/releases/download/v${version}/argo-linux-amd64.gz"
  echo "${checksum}"

  wget -nv "https://github.com/argoproj/argo-workflows/releases/download/v${version}/argo-linux-amd64.gz"
  echo "${checksum}  argo-linux-amd64.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum argo-linux-amd64.gz)"; exit 1; )

  gunzip argo-linux-amd64.gz
  mkdir -p "/opt/argo-${major_minor}/bin"
  install -o root -g root -m 755 argo-linux-amd64 "/opt/argo-${major_minor}/bin/argo"
}

# Versions

KUBECTL_1_23_5_CHECKSUM=715da05c56aa4f8df09cb1f9d96a2aa2c33a1232f6fd195e3ffce6e98a50a879
KUBECTL_1_22_4_CHECKSUM=21f24aa723002353eba1cc2668d0be22651f9063f444fd01626dce2b6e1c568c
KUBECTL_1_21_3_CHECKSUM=631246194fc1931cb897d61e1d542ef2321ec97adcb859a405d3b285ad9dd3d6
KUBECTL_1_20_9_CHECKSUM=9d76c4431e10e268dd7c6b53b27aaa62a6f26455013e1d7f6d85da86003539b9
KUBECTL_1_19_13_CHECKSUM=275a97f2c825e8148b46b5b7eb62c1c76bdbadcca67f5e81f19a5985078cc185
KUBECTL_1_18_20_CHECKSUM=66a9bb8e9843050340844ca6e72e67632b75b9ebb651559c49db22f35450ed2f

HELM_3_9_0_CHECKSUM=1484ffb0c7a608d8069470f48b88d729e88c41a1b6602f145231e8ea7b43b50a
HELM_3_8_2_CHECKSUM=6cb9a48f72ab9ddfecab88d264c2f6508ab3cd42d9c09666be16a7bf006bed7b
HELM_3_7_2_CHECKSUM=4ae30e48966aba5f807a4e140dad6736ee1a392940101e4d79ffb4ee86200a9e
HELM_3_6_3_CHECKSUM=07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262
HELM_3_5_4_CHECKSUM=a8ddb4e30435b5fd45308ecce5eaad676d64a5de9c89660b56face3fe990b318
HELM_3_4_2_CHECKSUM=cacde7768420dd41111a4630e047c231afa01f67e49cc0c6429563e024da4b98
HELM_3_3_4_CHECKSUM=b664632683c36446deeb85c406871590d879491e3de18978b426769e43a1e82c
HELM_3_2_4_CHECKSUM=8eb56cbb7d0da6b73cd8884c6607982d0be8087027b8ded01d6b2759a72e34b1

SOPS_3_7_3_CHECKSUM=53aec65e45f62a769ff24b7e5384f0c82d62668dd96ed56685f649da114b4dbb

LEGO_4_4_0_CHECKSUM=302a780a56dd52601aa5d1dc31e607599cb85b113830abe464001622ca8b80a2

ARGO_3_1_5_CHECKSUM=68ebb30e79aa5ab649dbd0feb6e227b0dcff2b2983c00e176cc523a9f883567b

install_sops 3.7.3

install_lego 4.4.0

install_helm 3.2.4
install_helm 3.3.4
install_helm 3.4.2
install_helm 3.5.4
install_helm 3.6.3
install_helm 3.7.2
install_helm 3.8.2
install_helm 3.9.0

install_kubectl 1.18.20
install_kubectl 1.19.13
install_kubectl 1.20.9
install_kubectl 1.21.3
install_kubectl 1.22.4
install_kubectl 1.23.5

install_argo 3.1.5

echo "Finished installing tools..."
