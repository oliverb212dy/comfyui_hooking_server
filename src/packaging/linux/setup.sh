#!/bin/bash
set -euo pipefail

PAYLOAD="$1"
fail() { echo "[SoyaComfy] $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || fail "Git이 없습니다. 배포본에 맞는 방법으로 Git을 설치해 주세요."
command -v ffmpeg >/dev/null 2>&1 || echo "[SoyaComfy] 경고: ffmpeg가 없습니다. 영상 처리를 위해 설치해 주세요."
command -v ffprobe >/dev/null 2>&1 || echo "[SoyaComfy] 경고: ffprobe가 없습니다. ffmpeg와 함께 설치해 주세요."

DATA_ROOT="${SOYA_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/SoyaComfy}"
mkdir -p "$DATA_ROOT"

UV_VERSION="0.11.8"
UV_TOOL_DIR="$DATA_ROOT/.tools/uv-$UV_VERSION"
UV_EXE="$UV_TOOL_DIR/uv"
if [ ! -x "$UV_EXE" ]; then
  (export UV_INSTALL_DIR="$UV_TOOL_DIR" UV_NO_MODIFY_PATH=1
   curl -LsSf "https://astral.sh/uv/$UV_VERSION/install.sh" | sh) \
    || fail "uv $UV_VERSION 설치에 실패했습니다."
fi

"$UV_EXE" run --no-project --no-config --python 3.12 python \
  "$PAYLOAD/update_payload.py" "$PAYLOAD" "$DATA_ROOT" \
  || fail "앱 업데이트에 실패했습니다. 오류를 확인한 뒤 다시 실행해 주세요."

chmod +x "$DATA_ROOT/src/run_en.sh"
exec bash "$DATA_ROOT/src/run_en.sh"
