#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tool/.venv/bin/python" "$ROOT/tool/generate_copyright_manual_docx.py"
