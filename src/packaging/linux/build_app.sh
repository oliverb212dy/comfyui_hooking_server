#!/bin/bash
# Build a portable Linux package containing the tracked application payload.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT_DIR="${1:-$REPO_ROOT/dist}"
VERSION="${2:-0.0.0}"
APP_DIR="$OUT_DIR/SoyaComfy"

[ "$(uname -s)" = "Linux" ] || { echo "[BUILD] Linux에서만 만들 수 있습니다: $(uname -s)" >&2; exit 1; }

command -v uv >/dev/null 2>&1 || { echo "[BUILD] uv is required" >&2; exit 1; }

echo "[BUILD] 출력: $APP_DIR (version=$VERSION)"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

# Only tracked files enter the package; never include local config, data, or output.
echo "[BUILD] 페이로드 복사 (git archive)"
git -C "$REPO_ROOT" archive --format=tar HEAD src config/.gitkeep data/.gitkeep \
  | tar -x -C "$APP_DIR"

for drop in tests upstream_patches tools .github updater_dev GitUpdater.exe opencode.json customprompt/tag_collector; do
  rm -rf "$APP_DIR/src/$drop"
done
find "$APP_DIR" -type d -name __pycache__ -prune -exec rm -rf '{}' +
find "$APP_DIR" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete

cp "$REPO_ROOT/src/packaging/linux/launcher.sh" "$APP_DIR/SoyaComfy"
cp "$REPO_ROOT/src/packaging/linux/setup.sh" "$APP_DIR/setup.sh"
cp "$REPO_ROOT/src/packaging/linux/FIRST_RUN.txt" "$APP_DIR/먼저 읽어주세요.txt"
cp "$REPO_ROOT/src/packaging/macos/update_payload.py" "$APP_DIR/update_payload.py"
cp "$REPO_ROOT/src/update_policy.py" "$APP_DIR/update_policy.py"
cp "$REPO_ROOT/src/preset_locations.py" "$APP_DIR/preset_locations.py"
cp "$REPO_ROOT/src/app_paths.py" "$APP_DIR/app_paths.py"
chmod +x "$APP_DIR/SoyaComfy" "$APP_DIR/setup.sh" "$APP_DIR/src/run_en.sh"

uv run --no-project --no-config --python 3.12 python \
  "$APP_DIR/update_payload.py" "$APP_DIR"
find "$APP_DIR" -type d -name __pycache__ -prune -exec rm -rf '{}' +
find "$APP_DIR" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete

cat > "$APP_DIR/VERSION" <<EOF
$VERSION
EOF

echo "[BUILD] 완료: $APP_DIR"
du -sh "$APP_DIR"
