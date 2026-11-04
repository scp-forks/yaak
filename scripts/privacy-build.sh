#!/usr/bin/env bash
# [privacy] scp-forks: build Yaak for macOS WITHOUT the updater and license
# features (no update.yaak.app / license.yaak.app traffic), then optionally
# install it to /Applications.
#
#   scripts/privacy-build.sh            # build only
#   scripts/privacy-build.sh --install  # build and replace /Applications/Yaak.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Node version pinned by the repo (.node-version), via nvm if available.
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.nvm/nvm.sh"
  nvm use "$(cat .node-version | cut -d. -f1)" >/dev/null
fi
echo "node $(node -v)"

# Version shown in the app = latest stable upstream tag in this branch's history.
VERSION="$(git describe --tags --abbrev=0 --match 'v[0-9]*' --exclude '*-*' | sed 's/^v//')"
echo "building Yaak $VERSION (privacy build, commit $(git rev-parse --short HEAD))"

npm install --no-audit --no-fund
(
  cd crates-tauri/yaak-app-client
  npx tauri build \
    --config tauri.privacy.conf.json \
    --config "{\"version\":\"$VERSION\"}"
)

# The build regenerates these committed wasm artifacts; restore them so the
# branch stays clean (they would only cause merge conflicts with upstream).
git restore --source=HEAD -- crates/yaak-templates/pkg crates/yaak-wasm/pkg

APP="$ROOT/target/release/bundle/macos/Yaak.app"
[ -d "$APP" ] || { echo "build output not found: $APP" >&2; exit 1; }
echo "built: $APP"

if [ "${1:-}" = "--install" ]; then
  if pgrep -f "/Applications/Yaak.app/" >/dev/null; then
    echo "Yaak is running; quit it and re-run with --install" >&2
    exit 1
  fi
  rm -rf /Applications/Yaak.app
  ditto "$APP" /Applications/Yaak.app
  echo "installed: /Applications/Yaak.app"
fi
