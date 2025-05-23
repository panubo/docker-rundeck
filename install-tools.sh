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
KUBECTL_1_33_1_CHECKSUM_X86_64=5de4e9f2266738fd112b721265a0c1cd7f4e5208b670f811861f699474a100a3
KUBECTL_1_33_1_CHECKSUM_AARCH64=d595d1a26b7444e0beb122e25750ee4524e74414bbde070b672b423139295ce6
KUBECTL_1_32_5_CHECKSUM_X86_64=aaa7e6ff3bd28c262f2d95c8c967597e097b092e9b79bcb37de699e7488e3e7b
KUBECTL_1_32_5_CHECKSUM_AARCH64=9edee84103e63c40a37cd15bd11e04e7835f65cb3ff5a50972058ffc343b4d96
KUBECTL_1_31_9_CHECKSUM_X86_64=720d31a15368ad56993c127a7d4fa2688a8520029c2e6be86b1a877ad6f92624
KUBECTL_1_31_9_CHECKSUM_AARCH64=1e6de599df408824f13602d73333c08c3528cfa5d6c8c98c633868a966882129
KUBECTL_1_30_13_CHECKSUM_X86_64=b92bd89b27386b671841d5970b926b645c2ae44e5ca0663cff0f1c836a1530ee
KUBECTL_1_30_13_CHECKSUM_AARCH64=afed1753b98ab30812203cb469e013082b25502c864f2889e8a0474aac497064

HELM_3_18_0_CHECKSUM_X86_64=961e587fc2c03807f8a99ac25ef063fa9e6915f1894729399cbb95d2a79af931
HELM_3_18_0_CHECKSUM_AARCH64=489c9d2d3ea4e095331249d74b4407fb5ac1d338c28429d70cdedccfe6e2b029
HELM_3_17_3_CHECKSUM_X86_64=ee88b3c851ae6466a3de507f7be73fe94d54cbf2987cbaa3d1a3832ea331f2cd
HELM_3_17_3_CHECKSUM_AARCH64=7944e3defd386c76fd92d9e6fec5c2d65a323f6fadc19bfb5e704e3eee10348e
HELM_3_16_4_CHECKSUM_X86_64=fc307327959aa38ed8f9f7e66d45492bb022a66c3e5da6063958254b9767d179
HELM_3_16_4_CHECKSUM_AARCH64=d3f8f15b3d9ec8c8678fbf3280c3e5902efabe5912e2f9fcf29107efbc8ead69
HELM_3_15_4_CHECKSUM_X86_64=11400fecfc07fd6f034863e4e0c4c4445594673fd2a129e701fe41f31170cfa9
HELM_3_15_4_CHECKSUM_AARCH64=fa419ecb139442e8a594c242343fafb7a46af3af34041c4eac1efcc49d74e626
HELM_3_14_4_CHECKSUM_X86_64=a5844ef2c38ef6ddf3b5a8f7d91e7e0e8ebc39a38bb3fc8013d629c1ef29c259
HELM_3_14_4_CHECKSUM_AARCH64=113ccc53b7c57c2aba0cd0aa560b5500841b18b5210d78641acfddc53dac8ab2
HELM_3_9_4_CHECKSUM_X86_64=31960ff2f76a7379d9bac526ddf889fb79241191f1dbe2a24f7864ddcb3f6560
HELM_3_9_4_CHECKSUM_AARCH64=d24163e466f7884c55079d1050968e80a05b633830047116cdfd8ae28d35b0c0

SOPS_3_10_2_CHECKSUM_X86_64=79b0f844237bd4b0446e4dc884dbc1765fc7dedc3968f743d5949c6f2e701739
SOPS_3_10_2_CHECKSUM_AARCH64=e91ddc04e6a78f5aed9e4fc347a279b539c43b74d99e6b8078e2f2f6f5b309f5

LEGO_4_23_1_CHECKSUM_X86_64=1fd60b1fd59c239bed22719a5de402cb745d1f933540cb1ec196e2c03e6e8882
LEGO_4_23_1_CHECKSUM_AARCH64=1114745108343286d4bff189b4bdee3cba9d07ebcacc673860d91ab951d31e0d

YQ_4_45_4_CHECKSUM_X86_64=4216b9d9fddd9c0c569b74161870f136800ac233e6c15a2e2b468e93fab54365
YQ_4_45_4_CHECKSUM_AARCH64=fe5269724dd3a503efb992187a6bf11c8a86da53e12bc654c8041dec684e9456

ORAS_1_2_3_CHECKSUM_X86_64=b4efc97a91f471f323f193ea4b4d63d8ff443ca3aab514151a30751330852827
ORAS_1_2_3_CHECKSUM_AARCH64=90e24e234dc6dffe73365533db66fd14449d2c9ae77381081596bf92f40f6b82

CRANE_0_20_5_CHECKSUM_X86_64=ad4cd9af2568c62c97e346de6d1295ee8c6ce3341f7b71cf02d41292b4532680
CRANE_0_20_5_CHECKSUM_AARCH64=228eba9af7e47677284fe414210008a8be5144a99186d56876a7ae1df85cd8ab

ARGO_3_6_7_CHECKSUM_X86_64=d27556595115c4649b0653eb42bd4cc3b5a1d3afc401385bbe1418c921da56c3
ARGO_3_6_7_CHECKSUM_AARCH64=c8bd7160d707ca352bd57b10c654085bb172545c63c2fbec7a8f3dbf1b69a624
ARGO_3_5_14_CHECKSUM_X86_64=162d1c77a3391cfb38515618a74160325a8a4022feb50a76895dc9c1b68a4632
ARGO_3_5_14_CHECKSUM_AARCH64=07603a26ffa90b32bf79213a409239e5c87221879a9abc3671c4dc6b3b862144
ARGO_3_4_18_CHECKSUM_X86_64=024095955a43eb8baac1405fb76f1b1098abdedfef4accefdbbd9b5295338528
ARGO_3_4_18_CHECKSUM_AARCH64=3bd2aa0dfd57f42c29dd098fb5d7936885a63b6ef08ff7fc9a7e4bc1ea3040e9
ARGO_3_1_5_CHECKSUM_X86_64=68ebb30e79aa5ab649dbd0feb6e227b0dcff2b2983c00e176cc523a9f883567b
ARGO_3_1_5_CHECKSUM_AARCH64=dc3c36081b6b49c8977dcffa9393a29e83568fba36a35f472caaac108674c03e

install_sops 3.10.2

install_lego 4.23.1

install_yq 4.45.4

install_oras 1.2.3

install_crane 0.20.5

# TODO remove 3.9.4
install_helm 3.9.4
install_helm 3.14.4
install_helm 3.15.4
install_helm 3.16.4
install_helm 3.17.3
install_helm 3.18.0

install_kubectl 1.30.13
install_kubectl 1.31.9
install_kubectl 1.32.5
install_kubectl 1.33.1

# TODO remove 3.1.5 
install_argo 3.1.5
install_argo 3.4.18
install_argo 3.5.14
install_argo 3.6.7

echo "Finished installing tools..."
