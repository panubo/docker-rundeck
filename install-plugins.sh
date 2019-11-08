#!/usr/bin/env bash

set -e

# Plugin Configuration

ANSIBLE_PLUGIN_VERSION=3.0.1
ANSIBLE_PLUGIN_CHECKSUM=d05b98f9ff58acc40efe178a6f19ca3a9297b27d9a5022f8b0859162cc9a9692
ANSIBLE_PLUGIN_SOURCE="https://github.com/Batix/rundeck-ansible-plugin/releases/download/${ANSIBLE_PLUGIN_VERSION}/ansible-plugin-${ANSIBLE_PLUGIN_VERSION}.jar"
ANSIBLE_PLUGIN_NAME="ansible-plugin-${ANSIBLE_PLUGIN_VERSION}.jar"

KUBERNETES_PLUGIN_VERSION=1.0.13
KUBERNETES_PLUGIN_CHECKSUM=b5486d0f8e9769e89241a463b942c7da41b7ce235ffeb8a6052de5ca0e31a70a
KUBERNETES_PLUGIN_SOURCE="https://github.com/rundeck-plugins/kubernetes/releases/download/${KUBERNETES_PLUGIN_VERSION}/kubernetes-plugin-${KUBERNETES_PLUGIN_VERSION}.zip"
KUBERNETES_PLUGIN_NAME="kubernetes-plugin-${KUBERNETES_PLUGIN_VERSION}.zip"

EC2NODES_PLUGIN_VERSION=1.5.12
EC2NODES_PLUGIN_CHECKSUM=0cd8bc577314b21a2ac6e08e0a4acd37e8dfcf95a659a007049e818188acf044
EC2NODES_PLUGIN_SOURCE="https://github.com/rundeck-plugins/rundeck-ec2-nodes-plugin/releases/download/v${EC2NODES_PLUGIN_VERSION}/rundeck-ec2-nodes-plugin-${EC2NODES_PLUGIN_VERSION}.jar"
EC2NODES_PLUGIN_NAME="rundeck-ec2-nodes-plugin-${EC2NODES_PLUGIN_VERSION}.jar"

SLACKWEBHOOK_PLUGIN_VERSION=0.11
SLACKWEBHOOK_PLUGIN_CHECKSUM=efce8fa7891371bb8540b55d7eef645741566d411b3dbed43e9b7fe2e4d099a0
SLACKWEBHOOK_PLUGIN_SOURCE="https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/releases/download/v${SLACKWEBHOOK_PLUGIN_VERSION}.dev/rundeck-slack-incoming-webhook-plugin-${SLACKWEBHOOK_PLUGIN_VERSION}.jar"
SLACKWEBHOOK_PLUGIN_NAME="rundeck-slack-incoming-webhook-plugin-${SLACKWEBHOOK_PLUGIN_VERSION}.jar"

mkdir -p /opt/rundeck-plugins/

for PLUGIN in ANSIBLE KUBERNETES EC2NODES SLACKWEBHOOK; do

  echo "Installing ${PLUGIN} plugin..."
  VERSION=$(eval "echo \${${PLUGIN}_PLUGIN_VERSION}")
  CHECKSUM=$(eval "echo \${${PLUGIN}_PLUGIN_CHECKSUM}")
  SOURCE=$(eval "echo \${${PLUGIN}_PLUGIN_SOURCE}")
  NAME=$(eval "echo \${${PLUGIN}_PLUGIN_NAME}")

  ( set -ex; wget --no-verbose -O /tmp/${NAME} -L ${SOURCE}; )
  echo "${CHECKSUM}  ${NAME}" > /tmp/SHA256SUM
  ( cd /tmp; sha256sum -c SHA256SUM; )
  mv /tmp/${NAME} /opt/rundeck-plugins/
  rm -f /tmp/SHA256SUM

done

echo "Finished installing plugins..."
rm -- "$0"
