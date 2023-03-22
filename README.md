# Rundeck

Docker image with [Rundeck](http://rundeck.org/) and [Ansible](https://www.ansible.com/).

This image configures Rundeck to use PAM authentication so we can use secure password hashes (SHA512 CRYPT) that aren't supported by JAAS (OBF, MD5 and CRYPT).

The configuration is fairly opinionated, and is probably not suitable as a general purpose image. The embedded H2 database is used to reduce external dependencies.

## Upgrading

Generally nothing needs to be done when upgrading versions.
However when upgrading to 4.x versions from 3.x or earlier, the following must be run against the data mount before starting the new container:

### 4.x upgrade

The following must be run to ensure that all the Rundeck files are owned by the correct uid/gid.

```
find . -uid 102 -exec chown --no-dereference 103 {} \;
find . -gid 103 -exec chgrp --no-dereference 104 {} \;
```

## Config

Mount the yaml config file into the container at `/config/config.yaml`. This could be done via a Docker volume mount or Kubernetes ConfigMap.

Example:

```
---

rundeck_uuid: "{{ inventory_hostname | to_uuid }}"

rundeck_server_url: http://localhost:4440

rundeck_api_auth_max_duration: "30d"

rundeck_users:
  - user: user1
    password: $6$Q8...$...
    roles: "user,admin"

  - user: user2
    password: $6$Q8...$...
    roles: "user"

  - user: user3
    password: $6$Q8...$...
    roles: "user,admin"

rundeck_tokens:
  - user: apiadmin
    token: somerandomstring
    role: admin
```

The global config (`/etc/rundeck`) directory is intended to be managed by the config options above and not editable at runtime.

The following volumes should be mounted externally to persist data and configuration between container restarts:

* `/config` - Rundeck Job and ACL configurations to load
* `/var/lib/rundeck/data` - Rundeck database (unless using an external database, not yet implemented in this image)
* `/var/lib/rundeck/logs` - Job logs
* `/home/rundeck` - Localhost working/home directory
* `/var/rundeck` - Rundeck projects
* `/var/log/rundeck` - Rundeck system logs

## Usage

Example runtime usage:

```
docker run --rm -it --name rundeck -p 4440:4440 \
  -v $(pwd)/config.yaml:/config/config.yaml \
  -v $(pwd)/test/lib:/var/lib/rundeck \
  -v $(pwd)/test/var:/var/rundeck \
  -v $(pwd)/test/log:/var/log/rundeck \
  docker.io/panubo/rundeck:latest
```

The container bootstrap does not support SSL. It is intended that this image is run behind an SSL terminating proxy such as Nginx, HAProxy or a cloud load balancer service.

For production use please use a release tag rather than the `latest` floating tag.

## Plugins

The following plugins are installed (excluding the base plugins):

* [Ansible](https://github.com/Batix/rundeck-ansible-plugin/)
* [EC2 Nodes](https://github.com/rundeck-plugins/rundeck-ec2-nodes-plugin/)
* [Slack Incoming Webhook](https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/)

## Tools

The following tools are pre-installed in the image

* [Ansible](https://www.ansible.com/)
* [Argo Workflows CLI](https://github.com/argoproj/argo-workflows/) **VERSIONED**
* [awscli](https://aws.amazon.com/cli/)
* [gcloud cli](https://cloud.google.com/sdk/)
* [mozilla/sops](https://github.com/mozilla/sops)
* [go-acme/lego](https://github.com/go-acme/lego)
* [helm](https://helm.sh/) **VERSIONED**
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) **VERSIONED**

**VERSIONED** tools are not in the PATH by default. Scripts need to call the version required directly. Versions of these tools are shortened to MAJOR.MINOR so any PATCH releases can be upgraded in-place.

The directory structure looks like:

```
/opt
├── argo-3.1
│   └── bin
│       └── argo
├── argo-3.4
│   └── bin
│       └── argo
├── bin
│   ├── lego
│   └── sops
├── helm-3.10
│   └── bin
│       └── helm
├── helm-3.11
│   └── bin
│       └── helm
├── helm-3.6
│   └── bin
│       └── helm
├── helm-3.7
│   └── bin
│       └── helm
├── helm-3.8
│   └── bin
│       └── helm
├── helm-3.9
│   └── bin
│       └── helm
├── kubectl-1.21
│   └── bin
│       └── kubectl
├── kubectl-1.22
│   └── bin
│       └── kubectl
├── kubectl-1.23
│   └── bin
│       └── kubectl
├── kubectl-1.24
│   └── bin
│       └── kubectl
├── kubectl-1.25
│   └── bin
│       └── kubectl
├── kubectl-1.26
│   └── bin
│       └── kubectl
└── rundeck-plugins
    ├── ansible-plugin-3.2.0.jar
    ├── rundeck-ec2-nodes-plugin-1.6.0.jar
    └── rundeck-slack-incoming-webhook-plugin-0.11.jar
```

## Status

Stable and production ready.

## Upgrade

Find the latest version of Rundeck at https://docs.rundeck.com/downloads.html
