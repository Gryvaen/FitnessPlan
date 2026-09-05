#!/usr/bin/env bash
# Build the user-manual PDF for copyright registration.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tool/.venv/bin/python" "$ROOT/tool/generate_copyright_manual_pdf.py"
