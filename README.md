# Rundeck

The docker image contains [Rundeck](http://rundeck.org/) and [Ansible](https://www.ansible.com/). The image configures Rundeck to use Pam authentication so we can use secure password hashes (SHA512 CRYPT) that aren't supported by JAAS (OBF, MD5 and CRYPT).

## Config

Mount the yaml config file into the container at `/config/config.yaml` (Could be done via a Docker volume mount or Kubernetes configmap)

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
    password:$6$Q8...$...
    roles: "user,admin"
```

The global config (/etc/rundeck) is intended to be managed by the config options above and not editable at runtime.

Following volumes should be mounted externally to persist data and config between container restarts.

* /var/lib/rundeck - Rundeck database, config and plugins
* /var/rundeck - Rundeck projects
* /var/log/rundeck - Logs

## Usage

```
docker run --rm -it --name rundeck -p 4440:4440 \
  -v $(pwd)/config.yaml:/config/config.yaml \
  -v $(pwd)/test/lib:/var/lib/rundeck \
  -v $(pwd)/test/var:/var/rundeck \
  -v $(pwd)/test/log:/var/log/rundeck \
  docker.io/panubo/rundeck:latest
```

The container bootstrap does not support SSL, it is intended that Rundeck is run behind an SSL terminating proxy such as Nginx, Haproxy or a cloud load balancer service.

## Plugins

The following plugins are installed (excluding the base plugins)

* Ansible
