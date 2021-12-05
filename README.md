# `trombik.home_assistant`

Managing Home Assistant.

The role installs it with `ansible` `pip` module and `python -m venv`.

Home Assistant is very picky about dependencies. The upstream even created a
Linux distribution for it. The dependencies have many `==x.y.z`. The author
does not think it is feasible to make a stable package for it.

The role does not, and will not, support TLS configuration for Home Assistant.
TLS should be terminated at a reverse proxy.

## Implemented features

* Installing Home Assistant with pip in a `venv`
* Managing configuration YAML files

## Not implemented features

* Managing users (and authentication tokens)
* Managing API configuration (show-stopper: user management)
* Installing integrations (show-stopper: API)
* Installing Home Assistant from packages (probably, will never be implemented)

## Known issues

After creating the initial user, Home Assistant asks the basic info, like name
and location. It does not respect what in the `configuration.yaml`.  After
another restart, the "General Configuration" page correctly says "Editor
disabled because config stored in configuration.yaml".

As its APIs are not fully implemented, what the role can do is very limited.
You will have to manually install integrations, add users, and create tokens.

Some non-python dependencies are installed by the role, but the author are not
sure they are correct because the complete dependencies are not documented. If
you find missing dependencies, please fill an Issue.

# Requirements

None

# Role Variables

| variable | description | default |
|----------|-------------|---------|


# Dependencies

None

# Example Playbook

The example below does:

* install `haproxy` as a reverse proxy for Home Assistant
* install Home Assistant with `pip` in `venv`

```yaml
---
- hosts: localhost
  roles:
    - trombik.haproxy
    - ansible-role-home_assistant
  vars:
    project_backend_host: 127.0.0.1
    project_backend_port: 8123
    home_assistant_wait_for_port: 80

    home_assistant_config:
      - name: configuration.yaml
        content: |
          # Configure a default setup of Home Assistant (frontend, api, etc)
          default_config:

          homeassistant:
            name: My Home Assistant
            latitude: 0.0
            longitude: 0.0
            elevation: 65535
            currency: USD
            time_zone: Asia/Tokyo
          http:
            server_host: {{ home_assistant_host }}
            server_port: {{ home_assistant_port }}
            trusted_proxies: 127.0.0.1
            use_x_forwarded_for: true

          # Text to speech
          tts:
            - platform: google_translate

          group: !include groups.yaml
          automation: !include automations.yaml
          script: !include scripts.yaml
          scene: !include scenes.yaml
      - name: secrets.yaml
        content: ""
        mode: "0640"
      - name: foo/bar.yaml
        content: ""
        mode: "0640"
      - name: groups.yaml
        content: ""
      - name: automations.yaml
        content: |
          []
      - name: scripts.yaml
        content: ""
      - name: scenes.yaml
        content: ""
    # ________________________________________haproxy
    os_haproxy_selinux_seport:
      FreeBSD: {}
      Debian: {}
      RedHat:
        ports:
          - 80
          - 8404
        proto: tcp
        setype: http_port_t
    haproxy_selinux_seport: "{{ os_haproxy_selinux_seport[ansible_os_family] }}"
    haproxy_config: |
      global
        daemon
      {% if ansible_os_family == 'FreeBSD' %}
      # FreeBSD package does not provide default
        maxconn 4096
        log /var/run/log local0 notice
          user {{ haproxy_user }}
          group {{ haproxy_group }}
      {% elif ansible_os_family == 'Debian' %}
        log /dev/log  local0
        log /dev/log  local1 notice
        chroot {{ haproxy_chroot_dir }}
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user {{ haproxy_user }}
        group {{ haproxy_group }}

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
          ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
          ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
      {% elif ansible_os_family == 'OpenBSD' %}
        log 127.0.0.1   local0 debug
        maxconn 1024
        chroot {{ haproxy_chroot_dir }}
        uid 604
        gid 604
        pidfile /var/run/haproxy.pid
      {% elif ansible_os_family == 'RedHat' %}
      log         127.0.0.1 local2
      chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
      maxconn     4000
      user        haproxy
      group       haproxy
      daemon
      {% endif %}

      defaults
        log global
        mode http
        timeout connect 5s
        timeout client 10s
        timeout server 10s
        # increase tunnel timeout for websocket
        timeout tunnel 3600s
        option  httplog
        option  dontlognull
        retries 3
        maxconn 2000
      {% if ansible_os_family == 'Debian' %}
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http
      {% elif ansible_os_family == 'OpenBSD' %}
        option  redispatch
      {% endif %}

      frontend http-in
        bind *:80
        default_backend servers

      backend servers
        option forwardfor
        server server1 {{ project_backend_host }}:{{ project_backend_port }} maxconn 32 check

      frontend stats
        bind *:8404
        mode http
        no log
        acl network_allowed src 127.0.0.0/8
        tcp-request connection reject if !network_allowed
        stats enable
        stats uri /
        stats refresh 10s
        stats admin if LOCALHOST

    os_haproxy_flags:
      FreeBSD: |
        haproxy_config="{{ haproxy_conf_file }}"
        #haproxy_flags="-q -f ${haproxy_config} -p ${pidfile}"
      Debian: |
        #CONFIG="/etc/haproxy/haproxy.cfg"
        #EXTRAOPTS="-de -m 16"
      OpenBSD: ""
      RedHat: |
        OPTIONS=""
    haproxy_flags: "{{ os_haproxy_flags[ansible_os_family] }}"
```

# License

```
Copyright (c) 2021 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
