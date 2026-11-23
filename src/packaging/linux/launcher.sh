#!/bin/bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$APP_DIR/setup.sh" "$APP_DIR"
