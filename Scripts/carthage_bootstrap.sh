#!/bin/bash
### FL Script Header V1 ##################
set -e
[ "${0:0:1}" != "/" ] && _prefix="$(pwd)/"
scpt_dir="$_prefix$(dirname "$0")"
lib_dir="$scpt_dir/zz_lib"
source "$lib_dir/common.sh" || exit 255
cd "$(dirname "$0")"/../ || exit 42
##########################################

rm -fr "Carthage/Build"
carthage bootstrap --use-ssh "$@"
