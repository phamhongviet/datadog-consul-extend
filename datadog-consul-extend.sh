#!/bin/sh

main() {
	check_env
}

check_env() {
	test -z "$API_KEY" && exit 1
	test -z "$API_ENDPOINT" && export API_ENDPOINT='https://app.datadoghq.com/api/'
	test -z "$CONSUL_API" && export CONSUL_API='http://localhost:8500/v1/'
}

get_services_list() {
	curl -s "${CONSUL_API}catalog/services" | jq -r 'keys | .[]'
}

get_service_hosts_number() {
	curl -s "${CONSUL_API}health/service/${1}?passing" | jq length
}

main $@
