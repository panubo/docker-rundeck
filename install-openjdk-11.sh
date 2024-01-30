#!/usr/bin/env bash

set -e 

export DEBIAN_FRONTEND=noninteractive

echo "deb http://deb.debian.org/debian bullseye main" > /etc/apt/sources.list.d/openjdk-11.list

cat <<EOF > /etc/apt/preferences.d/openjdk-11
Package: openjdk-11-jdk
Pin: release n=bullseye
Pin-Priority: 1001
EOF

apt-get update 
apt-get -y install openjdk-11-jdk

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Finished installing jdk 11"