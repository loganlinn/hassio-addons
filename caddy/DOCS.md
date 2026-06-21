# Internal Caddy

Internal Caddy runs Caddy as a Home Assistant add-on. It builds Caddy with the
Cloudflare DNS provider so Caddy can issue public certificates with the ACME
DNS-01 challenge while the service itself stays reachable only on the LAN.

The default generated config maps a single-label host under `public_domain` to
the same label under `backend_domain`:

```text
https://foo.internal.llinn.dev -> https://foo.internal
```

## Network Requirements

Configure LAN DNS so `*.internal.llinn.dev` resolves to the Home Assistant host
running this add-on. Configure your local service DNS so names like
`foo.internal` resolve to the backend service IP.

The add-on does not require inbound internet access. Certificate issuance uses
the Cloudflare DNS API and Let's Encrypt over outbound HTTPS.

## Configuration

```yaml
log_level: info
cloudflare_api_token: ""
public_domain: internal.llinn.dev
backend_domain: internal
backend_port: 443
upstream_dns_resolvers: 192.168.1.1
acme_dns_resolvers: 1.1.1.1 1.0.0.1
acme_propagation_timeout: 10m
acme_email: ""
upstream_tls_trust_pool_file: ""
upstream_tls_insecure_skip_verify: false
use_custom_caddyfile: false
```

### Option: `cloudflare_api_token`

Cloudflare API token used by Caddy for ACME DNS-01 challenges. Scope the token
to the DNS zone that contains `public_domain` and grant only:

- `Zone.Zone:Read`
- `Zone.DNS:Edit`

### Option: `public_domain`

Wildcard domain served by Caddy. With the default value, Caddy requests a
certificate for `*.internal.llinn.dev` and accepts hostnames such as
`foo.internal.llinn.dev`.

### Option: `backend_domain`

Local DNS suffix used for upstream services. With the default value,
`foo.internal.llinn.dev` proxies to `foo.internal`.

### Option: `backend_port`

HTTPS port used by upstream services.

### Option: `upstream_dns_resolvers`

Space-separated DNS resolver addresses Caddy uses to resolve upstream names such
as `foo.internal`. This should usually be your LAN DNS resolver or router IP.

### Option: `acme_dns_resolvers`

Space-separated public DNS resolver addresses Caddy uses to verify ACME TXT
record propagation. Keep this pointed at public resolvers so local split-DNS
rules do not hide Cloudflare challenge records.

### Option: `acme_propagation_timeout`

How long Caddy waits for ACME DNS challenge records to become visible.

### Option: `acme_email`

Optional ACME account email address.

### Option: `upstream_tls_trust_pool_file`

Optional path to a PEM CA bundle used to verify upstream HTTPS certificates. A
common location is `/share/caddy/upstream-ca.pem`.

### Option: `upstream_tls_insecure_skip_verify`

Disables upstream TLS certificate verification. Prefer
`upstream_tls_trust_pool_file`; use this only as a temporary diagnostic escape
hatch.

### Option: `use_custom_caddyfile`

When enabled, the add-on reads `/share/caddy/Caddyfile` instead of generating a
Caddyfile from add-on options. If the file does not exist, the add-on writes a
starter config there and exits so you can review it before restarting.

## Persistent Files

- `/data/caddy`: Caddy certificate and account storage.
- `/data/Caddyfile`: generated Caddyfile when `use_custom_caddyfile` is false.
- `/share/caddy/Caddyfile`: custom Caddyfile when `use_custom_caddyfile` is true.

## Troubleshooting

Check ACME propagation from a machine with `dig`:

```sh
dig @1.1.1.1 TXT _acme-challenge.internal.llinn.dev +short
dig @8.8.8.8 TXT _acme-challenge.internal.llinn.dev +short
```

If Cloudflare creates the TXT record but Caddy still times out, check
`acme_dns_resolvers`. If the TXT record never appears, check the Cloudflare API
token scope and zone.

