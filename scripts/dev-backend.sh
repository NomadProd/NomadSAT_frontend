#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec "$ROOT/NomadSAT_backend/scripts/dev-backend.sh"
