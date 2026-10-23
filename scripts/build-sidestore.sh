#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT/work/sidestore"

if ! command -v ldid >/dev/null 2>&1; then
  brew install ldid
fi
if ! command -v xcbeautify >/dev/null 2>&1; then
  brew install xcbeautify
fi

echo "==> building SideStore (unsigned)"
python3 scripts/ci/workflow.py build

test -f SideStore.ipa
echo "==> built $ROOT/work/sidestore/SideStore.ipa"
