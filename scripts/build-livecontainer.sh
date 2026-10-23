#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v xcbeautify >/dev/null 2>&1; then
  brew install xcbeautify
fi

mkdir -p "$ROOT/artifacts"
cd "$ROOT/work/livecontainer"

echo "==> archiving LiveContainer"
set -o pipefail
xcodebuild archive \
  -archivePath "$ROOT/artifacts/LiveContainer.xcarchive" \
  -scheme LiveContainer \
  -project LiveContainer.xcodeproj \
  -sdk iphoneos \
  -arch arm64 \
  -configuration Release \
  2>&1 | xcbeautify --renderer github-actions

test -d "$ROOT/artifacts/LiveContainer.xcarchive/Products/Applications/LiveContainer.app"
