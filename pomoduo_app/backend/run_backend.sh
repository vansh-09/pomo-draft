#!/usr/bin/env bash
set -euo pipefail

# Load .env if present
if [ -f "$(dirname "$0")/.env" ]; then
  # shellcheck source=/dev/null
  source "$(dirname "$0")/.env"
fi

export GROQ_API_KEY=${GROQ_API_KEY}
export GROQ_MODEL=${GROQ_MODEL:-groq/command-x}

echo "Starting backend with GROQ_MODEL=$GROQ_MODEL"
python "$(dirname "$0")/app.py"
