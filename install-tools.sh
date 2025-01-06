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

  echo "https://github.com/getsops/sops/releases/download/v${version}/sops-v${version}.linux.${!ARCH}"
  echo "${checksum}"

  wget -nv "https://github.com/getsops/sops/releases/download/v${version}/sops-v${version}.linux.${!ARCH}"
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

  echo "https://github.com/go-acme/lego/releases/download/v${version}/lego_v${version}_linux_${!ARCH}.tar.gz"
  echo "${checksum}"

  wget -nv "https://github.com/go-acme/lego/releases/download/v${version}/lego_v${version}_linux_${!ARCH}.tar.gz"
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

  echo "https://dl.k8s.io/release/v${version}/bin/linux/${!ARCH}/kubectl"
  echo "${checksum}"

  wget -nv "https://dl.k8s.io/release/v${version}/bin/linux/${!ARCH}/kubectl"
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
KUBECTL_1_31_4_CHECKSUM_X86_64=298e19e9c6c17199011404278f0ff8168a7eca4217edad9097af577023a5620f
KUBECTL_1_31_4_CHECKSUM_AARCH64=b97e93c20e3be4b8c8fa1235a41b4d77d4f2022ed3d899230dbbbbd43d26f872
KUBECTL_1_30_8_CHECKSUM_X86_64=7f39bdcf768ce4b8c1428894c70c49c8b4d2eee52f3606eb02f5f7d10f66d692
KUBECTL_1_30_8_CHECKSUM_AARCH64=e51d6a76fade0871a9143b64dc62a5ff44f369aa6cb4b04967d93798bf39d15b
KUBECTL_1_29_12_CHECKSUM_X86_64=35fc028853e6f5299a53f22ab58273ea2d882c0f261ead0a2eed5b844b12dbfb
KUBECTL_1_29_12_CHECKSUM_AARCH64=1cf2c00bb4f5ee6df69678e95af8ba9a4d4b1050ddefb0ae9d84b5c6f6c0e817
KUBECTL_1_28_15_CHECKSUM_X86_64=1f7651ad0b50ef4561aa82e77f3ad06599b5e6b0b2a5fb6c4f474d95a77e41c5
KUBECTL_1_28_15_CHECKSUM_AARCH64=7d45d9620e67095be41403ed80765fe47fcfbf4b4ed0bf0d1c8fe80345bda7d3
KUBECTL_1_27_16_CHECKSUM_X86_64=97ea7cd771d0c6e3332614668a40d2c5996f0053ff11b44b198ea84dba0818cb
KUBECTL_1_27_16_CHECKSUM_AARCH64=2f50cb29d73f696ffb57437d3e2c95b22c54f019de1dba19e2b834e0b4501eb9
KUBECTL_1_26_15_CHECKSUM_X86_64=b75f359e6fad3cdbf05a0ee9d5872c43383683bb8527a9e078bb5b8a44350a41
KUBECTL_1_26_15_CHECKSUM_AARCH64=1396313f0f8e84ab1879757797992f1af043e1050283532e0fd8469902632216
KUBECTL_1_25_16_CHECKSUM_X86_64=5a9bc1d3ebfc7f6f812042d5f97b82730f2bdda47634b67bddf36ed23819ab17
KUBECTL_1_25_16_CHECKSUM_AARCH64=d6c23c80828092f028476743638a091f2f5e8141273d5228bf06c6671ef46924

HELM_3_16_4_CHECKSUM_X86_64=fc307327959aa38ed8f9f7e66d45492bb022a66c3e5da6063958254b9767d179
HELM_3_16_4_CHECKSUM_AARCH64=d3f8f15b3d9ec8c8678fbf3280c3e5902efabe5912e2f9fcf29107efbc8ead69
HELM_3_15_4_CHECKSUM_X86_64=11400fecfc07fd6f034863e4e0c4c4445594673fd2a129e701fe41f31170cfa9
HELM_3_15_4_CHECKSUM_AARCH64=fa419ecb139442e8a594c242343fafb7a46af3af34041c4eac1efcc49d74e626
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

SOPS_3_9_3_CHECKSUM_X86_64=835ee92ef7269e1e40d69cbe5e1042975f3cd38044e8a0fa3c1a13543b7dcfaa
SOPS_3_9_3_CHECKSUM_AARCH64=49515aba9264e507eab884ebf902098046b8922d32f588f9a2beecb4a601d2ef

LEGO_4_21_0_CHECKSUM_X86_64=c8cc7fb636f8a5f1167e013dbd01485a72eb7393faf1776664c765a722cd6070
LEGO_4_21_0_CHECKSUM_AARCH64=d3971d6a5a1802ecfab1234f6d4db31d0e2c0a655dfc988dee96dd941b7a3abf

YQ_4_44_6_CHECKSUM_X86_64=09ea7643cba1cfde4c57abbadbf7fa242d7425db8ee93c0b184d68661cf3b1bd
YQ_4_44_6_CHECKSUM_AARCH64=b8ef016d33481af608e30a360693930f38721f13b271abaf182975b8631dc96d

ORAS_1_2_2_CHECKSUM_X86_64=bff970346470e5ef888e9f2c0bf7f8ee47283f5a45207d6e7a037da1fb0eae0d
ORAS_1_2_2_CHECKSUM_AARCH64=edd7195cbb8ba56c29ede413eefa10c8026201d63326017cd315841b4063aa56

CRANE_0_20_2_CHECKSUM_X86_64=c14340087103ba9dadf61d45acd20675490fd0ccbd56ac7901fc1b502137f44b
CRANE_0_20_2_CHECKSUM_AARCH64=aff0db48825124c9331ea310057214bd4e92c01aa2e414d539e9659841d9422a

ARGO_3_6_2_CHECKSUM_X86_64=4bbddd2bb98d5fa9de88ec80170955cfd086b53b5bc83d2ec0b342f4b6f252fc
ARGO_3_6_2_CHECKSUM_AARCH64=4e6500eb95f3c2c00d3304189309892faf2ec7ea438b126c6a3bacb8172e0d55
ARGO_3_5_13_CHECKSUM_X86_64=563e3903389da9fa24740b10ba996174326b623557acdb7efa46bfd94319ebc7
ARGO_3_5_13_CHECKSUM_AARCH64=52a6dc5925502a29b206d23f24ba2ad6745ce8307564f7ea13b834e725597e7d
ARGO_3_4_16_CHECKSUM_X86_64=af754014f0145e92147239be4092eceb16e81578346baf785609f2ee9caf50e8
ARGO_3_4_16_CHECKSUM_AARCH64=2dfae2844a0d79b18ebfd346a6dc9f5414e38b2a107c8e3371ab098ed5a28bac
ARGO_3_1_5_CHECKSUM_X86_64=68ebb30e79aa5ab649dbd0feb6e227b0dcff2b2983c00e176cc523a9f883567b
ARGO_3_1_5_CHECKSUM_AARCH64=dc3c36081b6b49c8977dcffa9393a29e83568fba36a35f472caaac108674c03e

install_sops 3.9.3

install_lego 4.21.0

install_yq 4.44.6

install_oras 1.2.2

install_crane 0.20.2

install_helm 3.9.4
install_helm 3.10.3
install_helm 3.11.3
install_helm 3.12.3
install_helm 3.13.3
install_helm 3.14.4
install_helm 3.15.4
install_helm 3.16.4

install_kubectl 1.25.16
install_kubectl 1.26.15
install_kubectl 1.27.16
install_kubectl 1.28.15
install_kubectl 1.29.12
install_kubectl 1.30.8
install_kubectl 1.31.4

install_argo 3.1.5
install_argo 3.4.16
install_argo 3.5.13
install_argo 3.6.2

echo "Finished installing tools..."
