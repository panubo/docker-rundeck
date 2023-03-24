#!/usr/bin/env bash
# This script sets up some test objects in a new rundeck instance
# It should be run from within a running rundeck container

set -euo pipefail
IFS=$'\n\t'

set -x

# Get the auth token from configure.sh
eval $(cat /configure.sh | grep RD_TOKEN)

# Create a test project
rd projects create -p TestProject

cat > /testjob.yaml <<EOF
- defaultTab: nodes
  description: ''
  executionEnabled: true
  id: ef188ba3-f92b-4b6a-ba46-cf160233b8d4
  loglevel: INFO
  name: Job1
  nodeFilterEditable: false
  plugins:
    ExecutionLifecycle: null
  scheduleEnabled: true
  sequence:
    commands:
    - script: |
        #!/usr/bin/env bash

        echo "Hello World!"
    keepgoing: false
    strategy: node-first
  uuid: ef188ba3-f92b-4b6a-ba46-cf160233b8d4
EOF

# Create a Job from the definition above
rd jobs load -p TestProject -f /testjob.yaml --duplicate update --format yaml

# Run a job to create a execution history
rd run -j Job1 -p TestProject

cat > /etc/rundeck/user.aclpolicy <<EOF
---
by:
  group: user
context:
  application: rundeck
for:
  project:
  - match:
      name: '.*'
    allow: [read]
description: User allowed access to read all projects

---
by:
  group: user
context:
  project: '.*' # all projects
for:
  resource:
  - equals:
      kind: event
    allow: [read]
  - equals:
      kind: node
    allow: [read]
  job:
  - allow: [read, run]
  adhoc:
  - deny: run
  node:
  - allow: [read, run]
description: User allowed read and job run on all projects
EOF

chown root:rundeck /etc/rundeck/user.aclpolicy
chmod 640 /etc/rundeck/user.aclpolicy
