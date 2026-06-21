# Logan's Home Assistant add-ons

This repository contains Home Assistant add-ons I run on my internal network.

## Add-ons

### Internal Caddy

`caddy/` runs Caddy as a Home Assistant add-on and builds Caddy with the
Cloudflare DNS provider. It is intended for internal wildcard HTTPS ingress,
for example mapping `https://foo.internal.llinn.dev` to
`https://foo.internal`.

## Installation

Add this repository to Home Assistant:

```text
https://github.com/loganlinn/hassio-addons
```

Then install the add-on from the Home Assistant add-on store.
