#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

flutter pub get

echo "Starting frontend on http://localhost:8080"
echo "Backend must be running: http://localhost:8000/docs"
echo "(Use ./scripts/dev-frontend-lan.sh for phone/LAN testing on 0.0.0.0)"
echo

flutter run -d chrome --web-port=8080
