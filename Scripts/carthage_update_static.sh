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
XCODE_XCCONFIG_FILE="$(pwd)/Xcode Supporting Files/StaticCarthageBuild.xcconfig" carthage update --use-ssh "$@"

# Update the xcfilelist files
cd "Carthage"
echo "# Static, Carthage-generated frameworks" >StaticFolderWorkaroundInput.xcfilelist
echo "# Links to actual Carthage-generated frameworks" >StaticFolderWorkaroundOutput.xcfilelist

cd "Build"
for os in *; do
	if [ ! -d "$os" ]; then continue; fi

	pushd "$os" >/dev/null
	for f in Static/*; do
		if [ ! -e "$f" ]; then continue; fi
		b="$(basename "$f")"
		echo "\$(SRCROOT)/Carthage/Build/$os/$f" >>../../StaticFolderWorkaroundInput.xcfilelist
		echo "\$(SRCROOT)/Carthage/Build/$os/$b" >>../../StaticFolderWorkaroundOutput.xcfilelist
	done
	popd >/dev/null
done

# Apply Carthage workaround
"$scpt_dir"/carthage_workaround_static_folder.sh "Static"
