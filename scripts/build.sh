#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"

mkdir -p "$DIST"
rm -f "$DIST/agent.zip"

echo "Building Linux ARM64 artifact via Docker..."
docker run --rm \
  --platform linux/arm64 \
  -v "$ROOT:/src" \
  -v "$DIST:/dist" \
  python:3.12-slim \
  bash -c "
    set -e
    apt-get update -qq && apt-get install -y zip -qq
    pip install -r /src/agent/requirements.txt -t /build --quiet --root-user-action=ignore
    cp /src/agent/main.py /build/
    cd /build && zip -r /dist/agent.zip . -x '*.pyc' -x '__pycache__/*' -q
    echo 'Build complete'
  "

echo "Built: $DIST/agent.zip"
