#!/usr/bin/env bash

set -e

( cd /ansible-bootstrap; ansible-playbook --connection local -i 'localhost,' --extra-vars @/config/config.yaml main.yml; )

. /etc/rundeck/profile

exec su -s /bin/bash rundeck -c "$rundeckd"
