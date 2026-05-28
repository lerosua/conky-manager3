#!/usr/bin/env bash

set -euo pipefail

app_name="conky-manager3"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$(dirname "$script_dir")/builds"
installer_dir="$script_dir/installer/deb"

cd "$script_dir"

"$script_dir/build-deb.sh"

rm -rf "$installer_dir"
mkdir -p "$installer_dir"

find "$build_dir" -maxdepth 1 -type f \( \
	-name "${app_name}_*.deb" -o \
	-name "${app_name}_*.buildinfo" -o \
	-name "${app_name}_*.changes" \
\) -exec cp -p -t "$installer_dir" {} +

echo "Package artifacts copied to $installer_dir"
ls -lh "$installer_dir"
