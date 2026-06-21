ARG CADDY_VERSION=2.11.4
ARG BUILD_FROM=ghcr.io/hassio-addons/base:21.0.0

FROM caddy:${CADDY_VERSION}-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

# hadolint ignore=DL3006
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    ca-certificates

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY rootfs /

RUN chmod a+x \
    /etc/s6-overlay/s6-rc.d/caddy/finish \
    /etc/s6-overlay/s6-rc.d/caddy/run \
    /usr/bin/run-caddy.sh

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="Logan Linn" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Logan Linn" \
    org.opencontainers.image.authors="Logan Linn" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/loganlinn/hassio-addons" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/caddy/DOCS.md" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${BUILD_REF}" \
    org.opencontainers.image.version="${BUILD_VERSION}"
