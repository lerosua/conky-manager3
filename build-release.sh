#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parent_dir="$(dirname "$script_dir")"
build_dir="$parent_dir/builds"
release_dir="$parent_dir/releases"

cd "$script_dir"

"$script_dir/build-deb.sh"

rm -rf "$release_dir"
mkdir -p "$release_dir"

cp -p "$build_dir"/* "$release_dir"/

"$script_dir/build-source.sh"

cp -p "$build_dir"/* "$release_dir"/

echo "Release artifacts copied to $release_dir"
ls -lh "$release_dir"
