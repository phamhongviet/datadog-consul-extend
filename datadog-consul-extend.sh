#!/bin/sh

main() {
	check_env
	while true; do
		post_metric_all_services post_service_hosts_number
		sleep 5
	done
}

check_env() {
	test -z "$API_KEY" && exit 1
	test -z "$API_ENDPOINT" && export API_ENDPOINT='https://app.datadoghq.com/api/'
	test -z "$CONSUL_API" && export CONSUL_API='http://localhost:8500/v1/'
}

post_metric_all_services() {
	local func=${1}
	for service in $(get_services_list); do
		${func} ${service} &
	done

}

get_services_list() {
	curl -s "${CONSUL_API}catalog/services" | jq -r 'keys | .[]'
}

get_service_hosts_number() {
	local service_name=${1}
	curl -s "${CONSUL_API}health/service/${service_name}?passing" | jq length
}

post_service_hosts_number() {
	local service_name=${1}
	local current_time=$(date +%s)
	local metric_name="consul.extend.${service_name}.n_hosts"
	local point=$(get_service_hosts_number ${service_name})
	local host=$(hostname)
	curl  -X POST -H "Content-type: application/json" \
	-d "{ \"series\" :
			 [{\"metric\":\"${metric_name}\",
			  \"points\":[[$current_time, ${point}]],
			  \"type\":\"gauge\",
			  \"host\":\"${host}\",
			  \"tags\":[]}
			]
		}" \
	"${API_ENDPOINT}v1/series?api_key=${API_KEY}"
}

main $@
