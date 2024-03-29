#!/usr/bin/env bash

set -e

# Plugin Configuration

ANSIBLE_PLUGIN_VERSION=3.2.0
ANSIBLE_PLUGIN_CHECKSUM=ccde36aaee1497afd27bd16ab240918282b69531760eb62d0beb9359cdb7f1f1
ANSIBLE_PLUGIN_SOURCE="https://github.com/Batix/rundeck-ansible-plugin/releases/download/v${ANSIBLE_PLUGIN_VERSION}/ansible-plugin-${ANSIBLE_PLUGIN_VERSION}.jar"
ANSIBLE_PLUGIN_NAME="ansible-plugin-${ANSIBLE_PLUGIN_VERSION}.jar"

EC2NODES_PLUGIN_VERSION=1.6.0
EC2NODES_PLUGIN_CHECKSUM=a56baa400bac29d98947f153cd319de0283cb76517b302332daad74e08531065
EC2NODES_PLUGIN_SOURCE="https://github.com/rundeck-plugins/rundeck-ec2-nodes-plugin/releases/download/v${EC2NODES_PLUGIN_VERSION}/rundeck-ec2-nodes-plugin-${EC2NODES_PLUGIN_VERSION}.jar"
EC2NODES_PLUGIN_NAME="rundeck-ec2-nodes-plugin-${EC2NODES_PLUGIN_VERSION}.jar"

SLACKWEBHOOK_PLUGIN_VERSION=0.11
SLACKWEBHOOK_PLUGIN_CHECKSUM=efce8fa7891371bb8540b55d7eef645741566d411b3dbed43e9b7fe2e4d099a0
SLACKWEBHOOK_PLUGIN_SOURCE="https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/releases/download/v${SLACKWEBHOOK_PLUGIN_VERSION}.dev/rundeck-slack-incoming-webhook-plugin-${SLACKWEBHOOK_PLUGIN_VERSION}.jar"
SLACKWEBHOOK_PLUGIN_NAME="rundeck-slack-incoming-webhook-plugin-${SLACKWEBHOOK_PLUGIN_VERSION}.jar"

mkdir -p /opt/rundeck-plugins/

for PLUGIN in ANSIBLE EC2NODES SLACKWEBHOOK; do

  echo "Installing ${PLUGIN} plugin..."
  VERSION=$(eval "echo \${${PLUGIN}_PLUGIN_VERSION}")
  CHECKSUM=$(eval "echo \${${PLUGIN}_PLUGIN_CHECKSUM}")
  SOURCE=$(eval "echo \${${PLUGIN}_PLUGIN_SOURCE}")
  NAME=$(eval "echo \${${PLUGIN}_PLUGIN_NAME}")

  ( set -ex; wget --no-verbose -O /tmp/${NAME} -L ${SOURCE}; )
  echo "${CHECKSUM}  ${NAME}" > /tmp/SHA256SUM
  ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected $(sha256sum /tmp/${NAME})"; exit 1; ))
  mv /tmp/${NAME} /opt/rundeck-plugins/
  rm -f /tmp/SHA256SUM

done

echo "Finished installing plugins..."
rm -- "$0"
