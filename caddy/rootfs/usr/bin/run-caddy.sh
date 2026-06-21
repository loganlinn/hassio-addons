#!/command/with-contenv bashio
# shellcheck shell=bash
set -euo pipefail

readonly GENERATED_CADDYFILE="/data/Caddyfile"
readonly CUSTOM_CADDYFILE="/share/caddy/Caddyfile"

validate_domain() {
	local value="${1}"
	local name="${2}"
	local require_dot="${3:-true}"

	if [[ ! "${value}" =~ ^[A-Za-z0-9.-]+$ ]] ||
		[[ "${value}" == .* ]] ||
		[[ "${value}" == *. ]]; then
		bashio::log.fatal "${name} must be a DNS suffix, got: ${value}"
	fi

	if [[ "${require_dot}" == "true" && "${value}" != *.* ]]; then
		bashio::log.fatal "${name} must contain at least one dot, got: ${value}"
	fi
}

regex_escape_domain() {
	local value="${1}"
	printf "%s" "${value//./\\.}"
}

render_caddyfile() {
	local target="${1}"
	local public_domain="${2}"
	local backend_domain="${3}"
	local backend_port="${4}"
	local upstream_dns_resolvers="${5}"
	local acme_dns_resolvers="${6}"
	local acme_propagation_timeout="${7}"
	local acme_email="${8}"
	local trust_pool_file="${9}"
	local insecure_skip_verify="${10}"
	local public_domain_regex

	public_domain_regex="$(regex_escape_domain "${public_domain}")"

	{
		echo "{"
		echo "	storage file_system /data/caddy"
		if [[ -n "${acme_email}" ]]; then
			echo "	email ${acme_email}"
		fi
		echo "}"
		echo
		echo "*.${public_domain} {"
		echo "	tls {"
		echo "		dns cloudflare {env.CF_API_TOKEN}"
		echo "		resolvers ${acme_dns_resolvers}"
		echo "		propagation_timeout ${acme_propagation_timeout}"
		echo "	}"
		echo
		echo "	@internal_host header_regexp internal_host Host ^(?P<upstream>[^.]+)\\.${public_domain_regex}(:[0-9]+)?$"
		echo
		echo "	reverse_proxy @internal_host {re.internal_host.upstream}.${backend_domain}:${backend_port} {"
		echo "		header_up Host {re.internal_host.upstream}.${backend_domain}"
		echo
		echo "		transport http {"
		echo "			resolvers ${upstream_dns_resolvers}"
		echo "			tls"
		echo "			tls_server_name {re.internal_host.upstream}.${backend_domain}"
		if [[ -n "${trust_pool_file}" ]]; then
			echo "			tls_trust_pool file ${trust_pool_file}"
		fi
		if [[ "${insecure_skip_verify}" == "true" ]]; then
			echo "			tls_insecure_skip_verify"
		fi
		echo "		}"
		echo "	}"
		echo "}"
	} >"${target}"
}

main() {
	local log_level
	local public_domain
	local backend_domain
	local backend_port
	local upstream_dns_resolvers
	local acme_dns_resolvers
	local acme_propagation_timeout
	local acme_email
	local trust_pool_file
	local insecure_skip_verify

	log_level="$(bashio::config 'log_level')"
	bashio::log.level "${log_level}"

	export CF_API_TOKEN
	CF_API_TOKEN="$(bashio::config 'cloudflare_api_token')"
	if [[ -z "${CF_API_TOKEN}" ]]; then
		bashio::log.fatal "cloudflare_api_token is required"
	fi

	public_domain="$(bashio::config 'public_domain')"
	backend_domain="$(bashio::config 'backend_domain')"
	backend_port="$(bashio::config 'backend_port')"
	upstream_dns_resolvers="$(bashio::config 'upstream_dns_resolvers')"
	acme_dns_resolvers="$(bashio::config 'acme_dns_resolvers')"
	acme_propagation_timeout="$(bashio::config 'acme_propagation_timeout')"
	acme_email="$(bashio::config 'acme_email')"
	trust_pool_file="$(bashio::config 'upstream_tls_trust_pool_file')"
	insecure_skip_verify="$(bashio::config 'upstream_tls_insecure_skip_verify')"

	validate_domain "${public_domain}" "public_domain"
	validate_domain "${backend_domain}" "backend_domain" false

	if [[ -n "${trust_pool_file}" && "${insecure_skip_verify}" == "true" ]]; then
		bashio::log.fatal \
			"upstream_tls_trust_pool_file and upstream_tls_insecure_skip_verify are mutually exclusive"
	fi

	mkdir -p /data/caddy /share/caddy

	if bashio::config.true 'use_custom_caddyfile'; then
		if [[ ! -f "${CUSTOM_CADDYFILE}" ]]; then
			render_caddyfile \
				"${CUSTOM_CADDYFILE}" \
				"${public_domain}" \
				"${backend_domain}" \
				"${backend_port}" \
				"${upstream_dns_resolvers}" \
				"${acme_dns_resolvers}" \
				"${acme_propagation_timeout}" \
				"${acme_email}" \
				"${trust_pool_file}" \
				"${insecure_skip_verify}"
			bashio::log.fatal \
				"Wrote starter config to ${CUSTOM_CADDYFILE}; review it, then restart the add-on"
		fi

		bashio::log.info "Starting Caddy with ${CUSTOM_CADDYFILE}"
		exec caddy run --config "${CUSTOM_CADDYFILE}" --adapter caddyfile
	fi

	render_caddyfile \
		"${GENERATED_CADDYFILE}" \
		"${public_domain}" \
		"${backend_domain}" \
		"${backend_port}" \
		"${upstream_dns_resolvers}" \
		"${acme_dns_resolvers}" \
		"${acme_propagation_timeout}" \
		"${acme_email}" \
		"${trust_pool_file}" \
		"${insecure_skip_verify}"

	caddy fmt --overwrite "${GENERATED_CADDYFILE}"
	caddy adapt --config "${GENERATED_CADDYFILE}" --adapter caddyfile >/dev/null

	bashio::log.info "Starting Caddy with generated configuration"
	exec caddy run --config "${GENERATED_CADDYFILE}" --adapter caddyfile
}

main "$@"
