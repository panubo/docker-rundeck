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

install_argocd() {
  local version checksum checksum_var version_parts major_minor
  version="${1}"
  checksum_var="ARGOCD_${version//\./_}_CHECKSUM_${ARCH^^}"
  checksum="${!checksum_var}"

  echo "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-linux-${!ARCH}"
  echo "${checksum}"

  wget -nv "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-linux-${!ARCH}"
  echo "${checksum}  argocd-linux-${!ARCH}" > SHA256SUM
  sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum argocd-linux-${!ARCH})"; exit 1; )

  mkdir -p "/opt/bin"
  install -o root -g root -m 755 argocd-linux-${!ARCH} "/opt/bin/argocd"
  rm argocd-linux-${!ARCH}
}

# Versions
# Both the amd64 and arm64 checksums must be included here.
KUBECTL_1_34_1_CHECKSUM_X86_64=7721f265e18709862655affba5343e85e1980639395d5754473dafaadcaa69e3
KUBECTL_1_34_1_CHECKSUM_AARCH64=420e6110e3ba7ee5a3927b5af868d18df17aae36b720529ffa4e9e945aa95450
KUBECTL_1_33_5_CHECKSUM_X86_64=6a12d6c39e4a611a3687ee24d8c733961bb4bae1ae975f5204400c0a6930c6fc
KUBECTL_1_33_5_CHECKSUM_AARCH64=6db7c5d846c3b3ddfd39f3137a93fe96af3938860eefdbf2429805ee1656e381
KUBECTL_1_32_9_CHECKSUM_X86_64=509ae171bac7ad3b98cc49f5594d6bc84900cf6860f155968d1059fde3be5286
KUBECTL_1_32_9_CHECKSUM_AARCH64=d5f6b45ad81b7d199187a28589e65f83406e0610b036491a9abaa49bfd04a708

HELM_3_19_0_CHECKSUM_X86_64=a7f81ce08007091b86d8bd696eb4d86b8d0f2e1b9f6c714be62f82f96a594496
HELM_3_19_0_CHECKSUM_AARCH64=440cf7add0aee27ebc93fada965523c1dc2e0ab340d4348da2215737fc0d76ad
HELM_3_18_6_CHECKSUM_X86_64=3f43c0aa57243852dd542493a0f54f1396c0bc8ec7296bbb2c01e802010819ce
HELM_3_18_6_CHECKSUM_AARCH64=5b8e00b6709caab466cbbb0bc29ee09059b8dc9417991dd04b497530e49b1737

SOPS_3_10_2_CHECKSUM_X86_64=79b0f844237bd4b0446e4dc884dbc1765fc7dedc3968f743d5949c6f2e701739
SOPS_3_10_2_CHECKSUM_AARCH64=e91ddc04e6a78f5aed9e4fc347a279b539c43b74d99e6b8078e2f2f6f5b309f5

LEGO_4_25_1_CHECKSUM_X86_64=a3c5a0732fe6977fd6a1e64d00f03b167de72de2dde43face4e16dd5118a1744
LEGO_4_25_1_CHECKSUM_AARCH64=90749e8ee8a5166bdd77adcca34688297b3d8c4677d790c98c3553bfcde1770e

YQ_4_47_1_CHECKSUM_X86_64=7583d471d9bfe88e32005e9d287952382df0469135f691e044443f610d707f4d
YQ_4_47_1_CHECKSUM_AARCH64=d20a542755c80be4099dbfc967240099f0d1e433e8b09e7aaafeb0145085f59b

ORAS_1_2_3_CHECKSUM_X86_64=b4efc97a91f471f323f193ea4b4d63d8ff443ca3aab514151a30751330852827
ORAS_1_2_3_CHECKSUM_AARCH64=90e24e234dc6dffe73365533db66fd14449d2c9ae77381081596bf92f40f6b82

CRANE_0_20_6_CHECKSUM_X86_64=c1d593d01551f2c9a3df5ca0a0be4385a839bd9b86d4a76e18d7b17d16559127
CRANE_0_20_6_CHECKSUM_AARCH64=fc0515857bc38e4ddd2d37a5ab03fb5959449c7b2d4ad759bcc1174ac0cad91b

ARGO_3_7_0_CHECKSUM_X86_64=dd174a7127c258b345af8e6ec3a27f790816a2e22d20b2835c09780174a1688c
ARGO_3_7_0_CHECKSUM_AARCH64=763353bdd6da2eed260319f766c3a0c823cd8313335c80259d4e564935152d1a
ARGO_3_6_10_CHECKSUM_X86_64=3dc3b39162d2b8196e18ebb434a66f8c14021bcdd9fbe64f41282acf20203fd2
ARGO_3_6_10_CHECKSUM_AARCH64=ead8b60958958dfe08e77a596d2f9df1fc17e825bd69d02ce883318cf0c9db2b
ARGO_3_4_18_CHECKSUM_X86_64=024095955a43eb8baac1405fb76f1b1098abdedfef4accefdbbd9b5295338528
ARGO_3_4_18_CHECKSUM_AARCH64=3bd2aa0dfd57f42c29dd098fb5d7936885a63b6ef08ff7fc9a7e4bc1ea3040e9

ARGOCD_3_0_11_CHECKSUM_X86_64=8320c021c085ed0d4fc3a7a7916c730f5836c6f6f9b10483164b5aabfaa640cd
ARGOCD_3_0_11_CHECKSUM_AARCH64=2f8e5c9167b647b5784745c276ec04320374607913ac35ed3ea4e25a29f2e770

# Single version install tools
install_sops 3.10.2
install_lego 4.25.1
install_yq 4.47.1
install_oras 1.2.3
install_crane 0.20.6
install_argocd 3.0.11

# Multi version install tools
install_helm 3.18.6
install_helm 3.19.0

install_kubectl 1.32.9
install_kubectl 1.33.5
install_kubectl 1.34.1

install_argo 3.4.18
install_argo 3.6.10
install_argo 3.7.0

echo "Finished installing tools..."
