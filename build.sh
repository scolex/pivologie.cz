#!/usr/bin/env bash
# Builds pivologie.cz with hrabal into public/. Cloudflare Workers Builds runs it on every push:
#
#   Build command:   ./build.sh
#   Deploy command:  npx wrangler deploy
#
# It works the same anywhere with git and Python 3: run ./build.sh and look into public/.
#
# hrabal needs Python 3.15, which Cloudflare's build image doesn't have, so uv fetches it, and hrabal's
# own uv.lock decides the versions of everything else. Build variables, both of them optional:
#
#   HRABAL_REF    branch, tag or commit of hrabal to build with, main by default
#   HRABAL_REPO   where to get hrabal from, for a fork or a local checkout
set -euo pipefail

UV_VERSION=0.13.0  # knows the final Python 3.15, 0.11 would still fetch a beta
ref="${HRABAL_REF:-main}"
repo="${HRABAL_REPO:-https://github.com/scolex/hrabal.git}"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "Getting hrabal $ref"
git -C "$work" init --quiet hrabal
git -C "$work/hrabal" fetch --quiet --depth 1 "$repo" "$ref"
git -C "$work/hrabal" checkout --quiet FETCH_HEAD
echo "Building with hrabal $(git -C "$work/hrabal" rev-parse --short HEAD)"

# uv in a venv of its own, since pip may not install into the system Python
python3 -m venv "$work/tools"
"$work/tools/bin/pip" install --quiet --disable-pip-version-check "uv==$UV_VERSION"

"$work/tools/bin/uv" run --project "$work/hrabal" --locked --no-dev --python 3.15 hrabal build
