#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$(dirname "$script_dir")/builds"

cd "$script_dir"

"$script_dir/build-deb.sh"

deb_file="$(find "$build_dir" -maxdepth 1 -type f -name 'conky-manager3_*.deb' | sort | tail -n 1)"

if [[ -z "$deb_file" ]]; then
	echo "No conky-manager3 .deb package found in $build_dir" >&2
	exit 1
fi

sudo apt install --reinstall "$deb_file"
