#!/bin/bash

export COLOR_CLEAR=$'\033[m'
export COLOR_ERROR=$'\033[1;31m'
export COLOR_WARNING=$'\033[0;31m'
export COLOR_ACTION=$'\033[0;34m'
export COLOR_INFO=$'\033[0;33m'
export COLOR_DEBUG=$'\033[0;37m'

echo_error() {
	echo "$COLOR_ERROR$*$COLOR_CLEAR"
}

echo_warning() {
	echo "$COLOR_WARNING$*$COLOR_CLEAR"
}

echo_action() {
	echo "$COLOR_ACTION$*$COLOR_CLEAR"
}

echo_normal() {
	echo "$*"
}

echo_info() {
	echo "$COLOR_INFO$*$COLOR_CLEAR"
}

echo_debug() {
	echo "$COLOR_DEBUG$*$COLOR_CLEAR"
}

fail_with_message() {
	exit_number="${1:-1}"
	shift
	echo_error "Error: $*"
	exit "$exit_number"
}


# First argument is the name of the variable in which you want the answer to be.
# Next arguments will compose the message to show to the user before starting
# the reading. An additional space will be added at the end of the message.
print_warning_message_read_response() {
	printf "$COLOR_WARNING"
	var_name="$1"
	eval $var_name=
	shift
	read -p "$* $COLOR_ACTION" $var_name
	printf "$COLOR_CLEAR"
}
