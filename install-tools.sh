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
KUBECTL_1_29_4_CHECKSUM_X86_64=10e343861c3cb0010161e703307ba907add2aeeeaffc6444779ad915f9889c88
KUBECTL_1_29_4_CHECKSUM_AARCH64=61537408eedcad064d7334384aed508a8aa1ea786311b87b505456a2e0535d36 
KUBECTL_1_28_8_CHECKSUM_X86_64=e02aad5c0bac52c970700b814645b62c4f18b634144398ac344875dbaf1072f8
KUBECTL_1_28_8_CHECKSUM_AARCH64=93d60dd36093b4c719f1f1bafcf59437c17cb2209341c7c94771e7dd9acdab33
KUBECTL_1_27_12_CHECKSUM_X86_64=d639eda39be2dce42fbec21e038942ab5734541715e3ea5fb29c9ad76686bd7f
KUBECTL_1_27_12_CHECKSUM_AARCH64=bfc6cb71041ebc0f048402988eccc107cfff2b866c864231c9ada05ab328e5bf
KUBECTL_1_26_15_CHECKSUM_X86_64=b75f359e6fad3cdbf05a0ee9d5872c43383683bb8527a9e078bb5b8a44350a41
KUBECTL_1_26_15_CHECKSUM_AARCH64=1396313f0f8e84ab1879757797992f1af043e1050283532e0fd8469902632216
KUBECTL_1_25_16_CHECKSUM_X86_64=5a9bc1d3ebfc7f6f812042d5f97b82730f2bdda47634b67bddf36ed23819ab17
KUBECTL_1_25_16_CHECKSUM_AARCH64=d6c23c80828092f028476743638a091f2f5e8141273d5228bf06c6671ef46924
KUBECTL_1_24_17_CHECKSUM_X86_64=3e9588e3326c7110a163103fc3ea101bb0e85f4d6fd228cf928fa9a2a20594d5
KUBECTL_1_24_17_CHECKSUM_AARCH64=66885bda3a202546778c77f0b66dcf7f576b5a49ff9456acf61329da784a602d

HELM_3_14_4_CHECKSUM_X86_64=a5844ef2c38ef6ddf3b5a8f7d91e7e0e8ebc39a38bb3fc8013d629c1ef29c259
HELM_3_14_4_CHECKSUM_AARCH64=113ccc53b7c57c2aba0cd0aa560b5500841b18b5210d78641acfddc53dac8ab2
HELM_3_13_3_CHECKSUM_X86_64=bbb6e7c6201458b235f335280f35493950dcd856825ddcfd1d3b40ae757d5c7d
HELM_3_13_3_CHECKSUM_AARCH64=44aaa094ae24d01e8c36e327e1837fd3377a0f9152626da088384c5bc6d94562
HELM_3_12_3_CHECKSUM_X86_64=1b2313cd198d45eab00cc37c38f6b1ca0a948ba279c29e322bdf426d406129b5
HELM_3_12_3_CHECKSUM_AARCH64=79ef06935fb47e432c0c91bdefd140e5b543ec46376007ca14a52e5ed3023088
HELM_3_11_3_CHECKSUM_X86_64=ca2d5d40d4cdfb9a3a6205dd803b5bc8def00bd2f13e5526c127e9b667974a89
HELM_3_11_3_CHECKSUM_AARCH64=9f58e707dcbe9a3b7885c4e24ef57edfb9794490d72705b33a93fa1f3572cce4
HELM_3_10_3_CHECKSUM_X86_64=950439759ece902157cf915b209b8d694e6f675eaab5099fb7894f30eeaee9a2
HELM_3_10_3_CHECKSUM_AARCH64=260cda5ff2ed5d01dd0fd6e7e09bc80126e00d8bdc55f3269d05129e32f6f99d
HELM_3_9_4_CHECKSUM_X86_64=31960ff2f76a7379d9bac526ddf889fb79241191f1dbe2a24f7864ddcb3f6560
HELM_3_9_4_CHECKSUM_AARCH64=d24163e466f7884c55079d1050968e80a05b633830047116cdfd8ae28d35b0c0

SOPS_3_8_1_CHECKSUM_X86_64=d6bf07fb61972127c9e0d622523124c2d81caf9f7971fb123228961021811697
SOPS_3_8_1_CHECKSUM_AARCH64=15b8e90ca80dc23125cd2925731035fdef20c749ba259df477d1dd103a06d621

LEGO_4_16_1_CHECKSUM_X86_64=e9826f955337c1fd825d21b073168692711985e25db013ff6b00e9a55a9644b4
LEGO_4_16_1_CHECKSUM_AARCH64=0669037c2bcff11d0599765c63f186dfc98397b6a827f5cb2e48e9e69c12626c

YQ_4_43_1_CHECKSUM_X86_64=049d1f3791cc25160a71b0bbe14a58302fb6a7e4462e07d5cbd543787a9ad815
YQ_4_43_1_CHECKSUM_AARCH64=92d00086075c267e2487857692da3f865d97ab0eabb10f9a01118cb3bbd3ecb7

ORAS_1_1_0_CHECKSUM_X86_64=e09e85323b24ccc8209a1506f142e3d481e6e809018537c6b3db979c891e6ad7
ORAS_1_1_0_CHECKSUM_AARCH64=e450b081f67f6fda2f16b7046075c67c9a53f3fda92fd20ecc59873b10477ab4

CRANE_0_19_1_CHECKSUM_X86_64=5f2b43c32a901adaaabaa78755d56cea71183954de7547cb4c4bc64b9ac6b2ff
CRANE_0_19_1_CHECKSUM_AARCH64=9118c29cdf2197441c4a934cf517df76c021ba12a70edc14ee9dc4dc08226680

ARGO_3_5_6_CHECKSUM_X86_64=6691b0aa1414b8b1cb8340f50eb7ab352517519f4f982ac682798f369a965c32
ARGO_3_5_6_CHECKSUM_AARCH64=0a245bb062d88c7a6a7cdb9e2f26141184897ea0966eedd91b6a0e06ab15b702
ARGO_3_4_16_CHECKSUM_X86_64=af754014f0145e92147239be4092eceb16e81578346baf785609f2ee9caf50e8
ARGO_3_4_16_CHECKSUM_AARCH64=2dfae2844a0d79b18ebfd346a6dc9f5414e38b2a107c8e3371ab098ed5a28bac
ARGO_3_1_5_CHECKSUM_X86_64=68ebb30e79aa5ab649dbd0feb6e227b0dcff2b2983c00e176cc523a9f883567b
ARGO_3_1_5_CHECKSUM_AARCH64=dc3c36081b6b49c8977dcffa9393a29e83568fba36a35f472caaac108674c03e

install_sops 3.8.1

install_lego 4.16.1

install_yq 4.43.1

install_oras 1.1.0

install_crane 0.19.1

install_helm 3.9.4
install_helm 3.10.3
install_helm 3.11.3
install_helm 3.12.3
install_helm 3.13.3
install_helm 3.14.4

install_kubectl 1.24.17
install_kubectl 1.25.16
install_kubectl 1.26.15
install_kubectl 1.27.12
install_kubectl 1.28.8
install_kubectl 1.29.4

install_argo 3.1.5
install_argo 3.4.16
install_argo 3.5.6

echo "Finished installing tools..."
