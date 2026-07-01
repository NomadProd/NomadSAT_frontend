#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

flutter pub get

LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || true)"
echo "Starting frontend on http://0.0.0.0:8080 (all interfaces)"
echo "On this Mac, open http://localhost:8080 (not http://0.0.0.0:8080)"
if [[ -n "$LAN_IP" ]]; then
  echo "Phone / LAN: http://${LAN_IP}:8080"
else
  echo "Phone / LAN: http://<your-mac-ip>:8080"
fi
echo "Backend must be running: ./scripts/dev-backend.sh"
echo

flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
