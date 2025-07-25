#!/usr/bin/env bash

# H2 database shell.
# Useful for fixing eg stuck migrations "update DATABASECHANGELOGLOCK set LOCKED = false where ID = 1;"

set -e

java -cp /opt/bin/h2.jar org.h2.tools.Shell -user sa -url jdbc:h2:/var/lib/rundeck/data/rundeckdb
