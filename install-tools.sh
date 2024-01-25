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

install_yq() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="YQ_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  echo "https://github.com/mikefarah/yq/releases/download/v${version}/yq_linux_${!ARCH}.tar.gz"
  echo "${checksum}"

  wget -nv "https://github.com/mikefarah/yq/releases/download/v${version}/yq_linux_${!ARCH}.tar.gz"
  echo "${checksum}  yq_linux_${!ARCH}.tar.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum yq_linux_${!ARCH}.tar.gz)"; exit 1; )

  tar -zxf yq_linux_${!ARCH}.tar.gz ./yq_linux_${!ARCH}
  install -o root -g root -m 755 yq_linux_${!ARCH} "/opt/bin/yq"
  rm yq_linux_${!ARCH}
}

install_oras() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="ORAS_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  echo "https://github.com/oras-project/oras/releases/download/v${version}/oras_${version}_linux_${!ARCH}.tar.gz"
  echo "${checksum}"

  wget -nv "https://github.com/oras-project/oras/releases/download/v${version}/oras_${version}_linux_${!ARCH}.tar.gz"
  echo "${checksum}  oras_${version}_linux_${!ARCH}.tar.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum oras_${version}_linux_${!ARCH}.tar.gz)"; exit 1; )

  tar -zxf oras_${version}_linux_${!ARCH}.tar.gz oras
  install -o root -g root -m 755 oras "/opt/bin/oras"
  rm oras
}

install_crane() {
  local version checksum checksum_var version_parts major_minor x86_64
  x86_64="x86_64"
  version="${1}"
  checksum_var="CRANE_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  echo "https://github.com/google/go-containerregistry/releases/download/v${version}/go-containerregistry_Linux_${!ARCH}.tar.gz"
  echo "${checksum}"

  wget -nv "https://github.com/google/go-containerregistry/releases/download/v${version}/go-containerregistry_Linux_${!ARCH}.tar.gz"
  echo "${checksum}  go-containerregistry_Linux_${!ARCH}.tar.gz" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum go-containerregistry_Linux_${!ARCH}.tar.gz)"; exit 1; )

  tar -zxf go-containerregistry_Linux_${!ARCH}.tar.gz crane
  install -o root -g root -m 755 crane "/opt/bin/crane"
  rm crane
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

HELM_3_12_3_CHECKSUM_X86_64=1b2313cd198d45eab00cc37c38f6b1ca0a948ba279c29e322bdf426d406129b5
HELM_3_12_3_CHECKSUM_AARCH64=79ef06935fb47e432c0c91bdefd140e5b543ec46376007ca14a52e5ed3023088
HELM_3_11_2_CHECKSUM_X86_64=781d826daec584f9d50a01f0f7dadfd25a3312217a14aa2fbb85107b014ac8ca
HELM_3_11_2_CHECKSUM_AARCH64=0a60baac83c3106017666864e664f52a4e16fbd578ac009f9a85456a9241c5db
HELM_3_10_3_CHECKSUM_X86_64=950439759ece902157cf915b209b8d694e6f675eaab5099fb7894f30eeaee9a2
HELM_3_10_3_CHECKSUM_AARCH64=260cda5ff2ed5d01dd0fd6e7e09bc80126e00d8bdc55f3269d05129e32f6f99d
HELM_3_9_4_CHECKSUM_X86_64=31960ff2f76a7379d9bac526ddf889fb79241191f1dbe2a24f7864ddcb3f6560
HELM_3_9_4_CHECKSUM_AARCH64=d24163e466f7884c55079d1050968e80a05b633830047116cdfd8ae28d35b0c0


SOPS_3_8_1_CHECKSUM_X86_64=d6bf07fb61972127c9e0d622523124c2d81caf9f7971fb123228961021811697
SOPS_3_8_1_CHECKSUM_AARCH64=15b8e90ca80dc23125cd2925731035fdef20c749ba259df477d1dd103a06d621

LEGO_4_14_2_CHECKSUM_X86_64=f5a978397802a2eb20771925ceb173dff88705b45fdbb2e68312269e205fa85d
LEGO_4_14_2_CHECKSUM_AARCH64=5050df1fb75085122cd253a3877e0d7ea07c4547964378a8f4753e1e2679cce6

YQ_4_40_5_CHECKSUM_X86_64=bccbf5ce1717ea5cec9662446b8bfa5863747ffb0a49a32e4c8dd23ada5c26fa
YQ_4_40_5_CHECKSUM_AARCH64=e90dae67f110746a4eb7ab8bafe7362f46d1a01cb37e7db7289c30cb7a4fd13c

ORAS_1_1_0_CHECKSUM_X86_64=e09e85323b24ccc8209a1506f142e3d481e6e809018537c6b3db979c891e6ad7
ORAS_1_1_0_CHECKSUM_AARCH64=e450b081f67f6fda2f16b7046075c67c9a53f3fda92fd20ecc59873b10477ab4

CRANE_0_18_0_CHECKSUM_X86_64=cdf4d426d965d9a8ba613d7ebf3addf93101aa2e853a3f08fbfdaed2823918f3
CRANE_0_18_0_CHECKSUM_AARCH64=3e81dee96fb20f8ffaa150c1136abc39c376c7183843a5e0a6164b9623613c56

ARGO_3_1_5_CHECKSUM_X86_64=68ebb30e79aa5ab649dbd0feb6e227b0dcff2b2983c00e176cc523a9f883567b
ARGO_3_1_5_CHECKSUM_AARCH64=dc3c36081b6b49c8977dcffa9393a29e83568fba36a35f472caaac108674c03e
ARGO_3_4_5_CHECKSUM_X86_64=0528ff0c0aa87a3f150376eee2f1b26e8b41eb96578c43d715c906304627d3a1
ARGO_3_4_5_CHECKSUM_AARCH64=6d953f667ded668f351bfeb94f32e34b70badc23770c11b55e3d2bc32caa274c

install_sops 3.8.1

install_lego 4.14.2

install_yq 4.40.5

install_oras 1.1.0

install_crane 0.18.0

install_helm 3.9.4
install_helm 3.10.3
install_helm 3.11.2
install_helm 3.12.3


install_kubectl 1.24.12
install_kubectl 1.25.8
install_kubectl 1.26.3

install_argo 3.1.5
install_argo 3.4.5

echo "Finished installing tools..."
