#!/usr/bin/env bash
# Build the source-code PDF for copyright registration.
# Usage: generate_copyright_source_pdf.sh --holder <姓名> [--completed YYYY-MM-DD]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec "$ROOT/tool/.venv/bin/python" "$ROOT/tool/copyright/generate_copyright_source_pdf.py" "$@"
