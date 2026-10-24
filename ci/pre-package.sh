#!/usr/bin/env bash
# Builds Union's dependency chain (recipes/ORDER) into output/, which the final
# Union build (recipe.yaml) then uses as a local channel. The shared nandi-conda
# workflow runs this before building recipe.yaml and uploads all of output/.
set -euo pipefail
cd "$(dirname "$0")/.."
while read -r name; do
  [ -n "$name" ] || continue
  echo "::group::build $name"
  pixi exec rattler-build build --recipe "recipes/$name/recipe.yaml" \
    -c conda-forge -c ./output --output-dir output --skip-existing local
  echo "::endgroup::"
done < "${ORDER_FILE:-recipes/ORDER}"
