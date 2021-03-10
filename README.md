# Rundeck

Docker image with [Rundeck](http://rundeck.org/) and [Ansible](https://www.ansible.com/).

This image configures Rundeck to use PAM authentication so we can use secure password hashes (SHA512 CRYPT) that aren't supported by JAAS (OBF, MD5 and CRYPT).

The configuration is fairly opinionated, and is probably not suitable as a general purpose image. H2 database (embedded) is used to reduce external dependencies.

## Config

Mount the yaml config file into the container at `/config/config.yaml` (Could be done via a Docker volume mount or Kubernetes configmap)

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
```

The global config (`/etc/rundeck`) directory is intended to be managed by the config options above and not editable at runtime.

The following volumes should be mounted externally to persist data and configuration between container restarts:

* /var/lib/rundeck/data - Rundeck database (unless using an external database, not yet implemented in this image)
* /var/lib/rundeck/logs - Job logs
* /home/rundeck - Localhost working/home directory
* /var/rundeck - Rundeck projects
* /var/log/rundeck - Rundeck system logs

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
* [Kubernetes](https://github.com/rundeck-plugins/kubernetes/)
* [Slack Incoming Webhook](https://github.com/higanworks/rundeck-slack-incoming-webhook-plugin/)

## Tools

The following tools are pre-installed in the image

* [Ansible](https://www.ansible.com/)
* [awscli](https://aws.amazon.com/cli/)
* [gcloud cli](https://cloud.google.com/sdk/)
* [mozilla/sops](https://github.com/mozilla/sops)
* [go-acme/lego](https://github.com/go-acme/lego)
* [helm](https://helm.sh/) **VERSIONED**
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) **VERSIONED**

**VERSIONED** tools are not in the PATH by default, script need to call the version they want directly. Versions of these tools are shortened to MAJOR.MINOR so any PATCH releases can be upgraded in-place.

The directory structure looks like:

```
/opt
├── bin
│   ├── lego
│   └── sops
├── helm-2.14
│   └── bin
│       └── helm
├── helm-2.9
│   └── bin
│       └── helm
├── helm-3.2
│   └── bin
│       └── helm
├── helm-3.4
│   └── bin
│       └── helm
├── kubectl-1.11
│   └── bin
│       └── kubectl
├── kubectl-1.12
│   └── bin
│       └── kubectl
├── kubectl-1.13
│   └── bin
│       └── kubectl
├── kubectl-1.14
│   └── bin
│       └── kubectl
└── kubectl-1.15
    └── bin
        └── kubectl
```

## Status

Stable and production ready.

## Upgrade

Find the latest version of rundeck at https://docs.rundeck.com/downloads.html
