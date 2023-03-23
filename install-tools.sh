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

# Get the arch
ARCH="$(uname -m)"
# These variables are used to convert from `uname -m` output to expected arch names.
# If a particular tool uses different names these variables can also be added to that tools function and updated to the tool specific values.
# When adding these variables to a tools function remember to add `aarch64 x86_64` to that functions `local` variables list.
aarch64="arm64"
x86_64="amd64"

install_sops() {
  local version checksum checksum_var
  version="${1}"
  checksum_var="SOPS_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  echo "https://github.com/mozilla/sops/releases/download/v${version}/sops-v${version}.linux.${!ARCH}"
  echo "${checksum}"

  wget -nv "https://github.com/mozilla/sops/releases/download/v${version}/sops-v${version}.linux.${!ARCH}"
  echo "${checksum}  sops-v${version}.linux.${!ARCH}" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum sops-v${version}.linux.${!ARCH})"; exit 1; )

  install -o root -g root -m 755 "sops-v${version}.linux.${!ARCH}" /opt/bin/sops
  rm "sops-v${version}.linux.${!ARCH}"
}

install_lego() {
  local version checksum checksum_var
  version="${1}"
  checksum_var="LEGO_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  echo "https://github.com/xenolf/lego/releases/download/v${version}/lego_v${version}_linux_${!ARCH}.tar.gz"
  echo "${checksum}"

  wget -nv "https://github.com/xenolf/lego/releases/download/v${version}/lego_v${version}_linux_${!ARCH}.tar.gz"
  echo "${checksum}  lego_v${version}_linux_${!ARCH}.tar.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum lego_v${version}_linux_${!ARCH}.tar.gz)"; exit 1; )

  tar -zxf "lego_v${version}_linux_${!ARCH}.tar.gz" lego
  install -o root -g root -m 755 lego /opt/bin/lego
  rm lego
}

install_helm() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="HELM_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  IFS='.' read -r -a version_parts <<<"${version}"
  major_minor="${version_parts[0]}.${version_parts[1]}"

  echo "https://get.helm.sh/helm-v${version}-linux-${!ARCH}.tar.gz"
  echo "${checksum}"

  wget -nv "https://get.helm.sh/helm-v${version}-linux-${!ARCH}.tar.gz"
  echo "${checksum}  helm-v${version}-linux-${!ARCH}.tar.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum helm-v${version}-linux-${!ARCH}.tar.gz)"; exit 1; )

  tar -zxf "helm-v${version}-linux-${!ARCH}.tar.gz" linux-${!ARCH}/helm

  mkdir -p "/opt/helm-${major_minor}/bin"
  install -o root -g root -m 755 linux-${!ARCH}/helm "/opt/helm-${major_minor}/bin/helm"
  rm linux-${!ARCH}/helm
}

install_kubectl() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="KUBECTL_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  IFS='.' read -r -a version_parts <<<"${version}"
  major_minor="${version_parts[0]}.${version_parts[1]}"

  echo "https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/linux/${!ARCH}/kubectl"
  echo "${checksum}"

  wget -nv "https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/linux/${!ARCH}/kubectl"
  echo "${checksum}  kubectl" > SHA256SUM
  sha256sum kubectl
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum kubectl)"; exit 1; )

  mkdir -p "/opt/kubectl-${major_minor}/bin"
  install -o root -g root -m 755 kubectl "/opt/kubectl-${major_minor}/bin/kubectl"
  rm kubectl
}

install_argo() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="ARGO_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  IFS='.' read -r -a version_parts <<<"${version}"
  major_minor="${version_parts[0]}.${version_parts[1]}"

  echo "https://github.com/argoproj/argo-workflows/releases/download/v${version}/argo-linux-${!ARCH}.gz"
  echo "${checksum}"

  wget -nv "https://github.com/argoproj/argo-workflows/releases/download/v${version}/argo-linux-${!ARCH}.gz"
  echo "${checksum}  argo-linux-${!ARCH}.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum argo-linux-${!ARCH}.gz)"; exit 1; )

  gunzip argo-linux-${!ARCH}.gz
  mkdir -p "/opt/argo-${major_minor}/bin"
  install -o root -g root -m 755 argo-linux-${!ARCH} "/opt/argo-${major_minor}/bin/argo"
  rm argo-linux-${!ARCH}
}

# Versions
# Both the amd64 and arm64 checksums must be included here.

KUBECTL_1_26_3_CHECKSUM_X86_64=026c8412d373064ab0359ed0d1a25c975e9ce803a093d76c8b30c5996ad73e75
KUBECTL_1_26_3_CHECKSUM_AARCH64=0f62cbb6fafa109f235a08348d74499a57bb294c2a2e6ee34be1fa83432fec1d
KUBECTL_1_25_8_CHECKSUM_X86_64=80e70448455f3d19c3cb49bd6ff6fc913677f4f240d368fa2b9f0d400c8cd16e
KUBECTL_1_25_8_CHECKSUM_AARCH64=28cf5f666cb0c11a8a2b3e5ae4bf93e56b74ab6051720c72bb231887bfc1a7c6
KUBECTL_1_24_12_CHECKSUM_X86_64=25875551d4242339bcc8cef0c18f0a0f631ea621f6fab1190a5aaab466634e7c
KUBECTL_1_24_12_CHECKSUM_AARCH64=a945095ceabc2b6f943c8c7c8484925b1b205738231fe7d34368a3e77dfe319b
KUBECTL_1_23_17_CHECKSUM_X86_64=f09f7338b5a677f17a9443796c648d2b80feaec9d6a094ab79a77c8a01fde941
KUBECTL_1_23_17_CHECKSUM_AARCH64=c4a48fdc6038beacbc5de3e4cf6c23639b643e76656aabe2b7798d3898ec7f05
KUBECTL_1_22_4_CHECKSUM_X86_64=21f24aa723002353eba1cc2668d0be22651f9063f444fd01626dce2b6e1c568c
KUBECTL_1_22_4_CHECKSUM_AARCH64=3fcec0284c0fdfc22e89a5b73ebd7f51120cc3505a11a4f6d6f819d46a40b26a
KUBECTL_1_21_3_CHECKSUM_X86_64=631246194fc1931cb897d61e1d542ef2321ec97adcb859a405d3b285ad9dd3d6
KUBECTL_1_21_3_CHECKSUM_AARCH64=2be58b5266faeeb93f38fa72d36add13a950643d2ae16a131f48f5a21c66ef23

HELM_3_11_2_CHECKSUM_X86_64=781d826daec584f9d50a01f0f7dadfd25a3312217a14aa2fbb85107b014ac8ca
HELM_3_11_2_CHECKSUM_AARCH64=0a60baac83c3106017666864e664f52a4e16fbd578ac009f9a85456a9241c5db
HELM_3_10_3_CHECKSUM_X86_64=950439759ece902157cf915b209b8d694e6f675eaab5099fb7894f30eeaee9a2
HELM_3_10_3_CHECKSUM_AARCH64=260cda5ff2ed5d01dd0fd6e7e09bc80126e00d8bdc55f3269d05129e32f6f99d
HELM_3_9_4_CHECKSUM_X86_64=31960ff2f76a7379d9bac526ddf889fb79241191f1dbe2a24f7864ddcb3f6560
HELM_3_9_4_CHECKSUM_AARCH64=d24163e466f7884c55079d1050968e80a05b633830047116cdfd8ae28d35b0c0
HELM_3_8_2_CHECKSUM_X86_64=6cb9a48f72ab9ddfecab88d264c2f6508ab3cd42d9c09666be16a7bf006bed7b
HELM_3_8_2_CHECKSUM_AARCH64=238db7f55e887f9c1038b7e43585b84389a05fff5424e70557886cad1635b3ce
HELM_3_7_2_CHECKSUM_X86_64=4ae30e48966aba5f807a4e140dad6736ee1a392940101e4d79ffb4ee86200a9e
HELM_3_7_2_CHECKSUM_AARCH64=b0214eabbb64791f563bd222d17150ce39bf4e2f5de49f49fdb456ce9ae8162f
HELM_3_6_3_CHECKSUM_X86_64=07c100849925623dc1913209cd1a30f0a9b80a5b4d6ff2153c609d11b043e262
HELM_3_6_3_CHECKSUM_AARCH64=6fe647628bc27e7ae77d015da4d5e1c63024f673062ac7bc11453ccc55657713

SOPS_3_7_3_CHECKSUM_X86_64=53aec65e45f62a769ff24b7e5384f0c82d62668dd96ed56685f649da114b4dbb
SOPS_3_7_3_CHECKSUM_AARCH64=4945313ed0dfddba52a12ab460d750c91ead725d734039493da0285ad6c5f032

LEGO_4_4_0_CHECKSUM_X86_64=302a780a56dd52601aa5d1dc31e607599cb85b113830abe464001622ca8b80a2
LEGO_4_4_0_CHECKSUM_AARCH64=abe0e795be083143bc72ffe0f62670d96d1d33caeec2649b452d6fe9ac7ede4f

ARGO_3_1_5_CHECKSUM_X86_64=68ebb30e79aa5ab649dbd0feb6e227b0dcff2b2983c00e176cc523a9f883567b
ARGO_3_1_5_CHECKSUM_AARCH64=dc3c36081b6b49c8977dcffa9393a29e83568fba36a35f472caaac108674c03e
ARGO_3_4_5_CHECKSUM_X86_64=0528ff0c0aa87a3f150376eee2f1b26e8b41eb96578c43d715c906304627d3a1
ARGO_3_4_5_CHECKSUM_AARCH64=6d953f667ded668f351bfeb94f32e34b70badc23770c11b55e3d2bc32caa274c

install_sops 3.7.3

install_lego 4.4.0

install_helm 3.6.3
install_helm 3.7.2
install_helm 3.8.2
install_helm 3.9.4
install_helm 3.10.3
install_helm 3.11.2

install_kubectl 1.21.3
install_kubectl 1.22.4
install_kubectl 1.23.17
install_kubectl 1.24.12
install_kubectl 1.25.8
install_kubectl 1.26.3

install_argo 3.1.5
install_argo 3.4.5

echo "Finished installing tools..."
