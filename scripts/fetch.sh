#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
source "$ROOT/pins.env"

fetch_repo() {
  local name="$1" url="$2" sha="$3" dir="$ROOT/work/$1"

  if [ -d "$dir/.git" ] && [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)" = "$sha" ]; then
    echo "==> $name already at $sha"
  else
    echo "==> fetching $name @ $sha"
    rm -rf "$dir"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" remote add origin "$url"
    git -C "$dir" fetch --depth 1 origin "$sha"
    git -C "$dir" checkout -q FETCH_HEAD
  fi

  echo "==> updating submodules for $name"
  git -C "$dir" submodule update --init --recursive --depth 1
}

fetch_repo livecontainer "$LC_REPO" "$LC_SHA"
fetch_repo sidestore "$SS_REPO" "$SS_SHA"

echo "==> applying patches"
for patch in "$ROOT"/patches/*.patch; do
  [ -e "$patch" ] || continue
  name="$(basename "$patch")"
  if git -C "$ROOT/work/livecontainer" apply --reverse --check "$patch" >/dev/null 2>&1; then
    echo "    $name already applied"
  else
    echo "    applying $name"
    git -C "$ROOT/work/livecontainer" apply --3way "$patch"
  fi
done

echo "==> sources ready"
git -C "$ROOT/work/livecontainer" log -1 --oneline
git -C "$ROOT/work/sidestore" log -1 --oneline
