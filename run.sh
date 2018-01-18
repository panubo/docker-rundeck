#!/bin/bash

set -e

( cd /ansible-bootstrap; ansible-playbook --connection local -i 'localhost,' --extra-vars @/config/config.yaml main.yml; )

prog="rundeckd"

[ -e /etc/default/$prog ] && . /etc/default/$prog

. /etc/rundeck/profile


su -s /bin/bash rundeck -c "$rundeckd"
