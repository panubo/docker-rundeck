#!/usr/bin/env bash
# Script to run the h2 v2 migration from https://github.com/rundeck-plugins/h2-v2-migration
# This script needs to be run from within a rundeck container with all volumes mounted as usual

set -euo pipefail
IFS=$'\n\t'

git -C /var/lib/rundeck/data clone https://github.com/rundeck-plugins/h2-v2-migration.git

mkdir /var/lib/rundeck/data/h2-v2-migration/backup

cp /var/lib/rundeck/data/rundeckdb.* /var/lib/rundeck/data/h2-v2-migration/backup/

sed -i 's/grailsdb/rundeckdb/g' /var/lib/rundeck/data/h2-v2-migration/migration.sh

(
  cd /var/lib/rundeck/data/h2-v2-migration
  /var/lib/rundeck/data/h2-v2-migration/migration.sh -f /var/lib/rundeck/data/h2-v2-migration/backup/rundeckdb -u sa
)

cp /var/lib/rundeck/data/h2-v2-migration/output/v2/data/rundeckdb.mv.db /var/lib/rundeck/data/rundeckdb.mv.db

chown rundeck:rundeck /var/lib/rundeck/data/rundeckdb.mv.db
