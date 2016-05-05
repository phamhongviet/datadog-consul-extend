#!/bin/sh

main() {
	check_env
}

check_env() {
	test -z "$API_KEY" && exit 1
	test -z "$API_ENDPOINT" && export API_ENDPOINT='https://app.datadoghq.com/api/'
}

main $@
