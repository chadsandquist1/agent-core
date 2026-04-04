#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$(mktemp -d)"
DIST="$ROOT/dist"

mkdir -p "$DIST"

echo "Installing dependencies..."
pip install -r "$ROOT/agent/requirements.txt" -t "$BUILD_DIR" --quiet

echo "Copying agent code..."
cp "$ROOT/agent/main.py" "$BUILD_DIR/"

echo "Zipping..."
(cd "$BUILD_DIR" && zip -r "$DIST/agent.zip" . -x "*.pyc" -x "__pycache__/*")

rm -rf "$BUILD_DIR"
echo "Built: $DIST/agent.zip"
