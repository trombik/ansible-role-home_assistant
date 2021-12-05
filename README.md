# `trombik.home_assistant`

Managing Home Assistant.

## Implemented features

* Installing Home Assistant with pip in a `venv`
* Managing configuration YAML files

## Not implemented features

* Managing users (and authentication tokens)
* Managing API configuration (show-stopper: user management)
* Installing integrations (show-stopper: API)
* Installing Home Assistant from packages (probably, will never be implemented)

## Known issues

* After creating the initial user, Home Assistant asks the basic info, like
  name and location. It does not respect what in the `configuration.yaml`.
  After another restart, the "General Configuration" page correctly says
  "Editor disabled because config stored in configuration.yaml".

* As its APIs are not fully implemented, what the role can do is very limited.
  You will have to manually install integrations, add users, and create
  tokens.

# Requirements

None

# Role Variables

| variable | description | default |
|----------|-------------|---------|


# Dependencies

None

# Example Playbook

```yaml
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
