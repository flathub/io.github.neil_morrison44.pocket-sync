#!/usr/bin/env bash

set -e

get_app_version()
{
	TAG=$(yq -r '.["modules"].[] | select(.name=="pocket-sync")["sources"][] | select(.url=="https://github.com/neil-morrison44/pocket-sync")["tag"]' io.github.neil_morrison44.pocket-sync.yaml 2> /dev/null)
	if [ -z "$TAG" ] ; then
		echo "Could not extract current release tag from io.github.neil_morrison44.pocket-sync.yaml"
		exit 1
	fi
	echo $TAG
}

TAG=$(get_app_version)

if ! command -v flatpak-node-generator >/dev/null 2>&1 ; then
	echo "flatpak-node-generator missing"
	echo "Install it from https://github.com/flatpak/flatpak-builder-tools/tree/master/node#usage"
	exit 1
fi

rm -rf _deps_build
echo "Checking out pocket-sync $VERSION"
git clone https://github.com/neil-morrison44/pocket-sync -b "$TAG" _deps_build
cd _deps_build
echo "Generating node dependencies"
npm-20 i --package-lock-only
flatpak-node-generator npm package-lock.json
mv generated-sources.json ../node-sources.json

pushd src-tauri
wget https://github.com/flatpak/flatpak-builder-tools/raw/refs/heads/master/cargo/flatpak-cargo-generator.py
chmod +x flatpak-cargo-generator.py
echo "Generating cargo dependencies"
./flatpak-cargo-generator.py Cargo.lock
mv generated-sources.json ../../cargo-sources.json
popd
