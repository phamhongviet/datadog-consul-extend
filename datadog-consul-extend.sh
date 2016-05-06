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
	${func} $(get_services_list)
}

get_services_list() {
	curl -s "${CONSUL_API}catalog/services" | jq -r 'keys | .[]'
}

get_service_hosts_number() {
	local service_name=${1}
	curl -s "${CONSUL_API}health/service/${service_name}?passing" | jq length
}

post_service_hosts_number() {
	local services=${@}
	local current_time=$(date +%s)
	local metric_name=
	local point=
	local host=$(hostname)
	local payload="{}"
	curl  -X POST -H "Content-type: application/json" \
	-d "{ \"series\" :[
	$(for srv in ${services}; do
		metric_name="consul.extend.${srv}.n_hosts"
		point=$(get_service_hosts_number ${srv})
		construct_metric "$metric_name" "$current_time" "$point" "$host"
	done | paste -s -d,)
		]}" \
	"${API_ENDPOINT}v1/series?api_key=${API_KEY}"
}

construct_metric() {
	local metric_name=$1
	local current_time=$2
	local point=$3
	local host=$4
	echo "{\"metric\":\"${metric_name}\",
	\"points\":[[${current_time},${point}]],
	\"type\":\"gauge\",
	\"host\":\"${host}\",
	\"tags\":[]}"
}

main $@
