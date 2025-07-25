#!/usr/bin/env bash
# Script to run the h2 v3 migration from https://github.com/rundeck-plugins/h2-v2-migration
# This script needs to be run from within a rundeck container with all volumes mounted as usual

set -euo pipefail
IFS=$'\n\t'

if [[ -e /var/lib/rundeck/data/rundeckdb.mv.db.done-v3 ]]; then
  echo "Already migrated to V3, /var/lib/rundeck/data/rundeckdb.mv.db.done-v3 exists."
  exit
fi

set -x

if [[ -d /var/lib/rundeck/data/h2-v2-migration ]]; then
  git -C /var/lib/rundeck/data/h2-v2-migration fetch
  git -C /var/lib/rundeck/data/h2-v2-migration reset --hard "origin/main"
else
  git -C /var/lib/rundeck/data clone https://github.com/rundeck-plugins/h2-v2-migration.git
fi

mkdir /var/lib/rundeck/data/h2-v2-migration/backup-pre-v3

cp /var/lib/rundeck/data/rundeckdb.* /var/lib/rundeck/data/h2-v2-migration/backup-pre-v3/

sed -i 's/grailsdb/rundeckdb/g' /var/lib/rundeck/data/h2-v2-migration/migration.sh

(
  cd /var/lib/rundeck/data/h2-v2-migration
  /var/lib/rundeck/data/h2-v2-migration/migration.sh -f /var/lib/rundeck/data/h2-v2-migration/backup-pre-v3/rundeckdb -u sa
)

cp /var/lib/rundeck/data/h2-v2-migration/output/v3/data/rundeckdb.mv.db /var/lib/rundeck/data/rundeckdb.mv.db

chown rundeck:rundeck /var/lib/rundeck/data/rundeckdb.mv.db

# Create done-v3 file to prevent trying to migrate again
touch /var/lib/rundeck/data/rundeckdb.mv.db.done-v3
