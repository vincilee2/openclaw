#!/usr/bin/env bash
# Zammad API Configuration
#
# Override priority (high → low):
#   1. Environment variable: ZAMMAD_URL / ZAMMAD_TOKEN
#   2. Config file: ~/.zammad-config
#   3. Not set → error with setup prompt
#
# Examples:
#   ZAMMAD_URL=https://zammad.example.com ZAMMAD_TOKEN=xxx bash zammad-user-list.sh
#   bash zammad-ticket-create.sh  # uses ~/.zammad-config

ZAMMAD_CONFIG_FILE="${ZAMMAD_CONFIG_FILE:-$HOME/.zammad-config}"
ZAMMAD_TIMEOUT="${ZAMMAD_TIMEOUT:-30}"

# ─── Config Resolution ──────────────────────────────────

_zammad_load_config() {
  if [ -f "$ZAMMAD_CONFIG_FILE" ]; then
    source "$ZAMMAD_CONFIG_FILE"
  fi
}

_zammad_ensure_config() {
  _zammad_load_config
  ZAMMAD_URL="${ZAMMAD_URL:-}"
  ZAMMAD_TOKEN="${ZAMMAD_TOKEN:-}"

  if [ -z "$ZAMMAD_URL" ] || [ -z "$ZAMMAD_TOKEN" ]; then
    cat >&2 <<'SETUP'
╔══════════════════════════════════════════════════╗
║  Zammad - Configuration Required                ║
║                                                  ║
║  No Zammad URL or API token configured.         ║
║  Run the setup command first:                   ║
║                                                  ║
║  bash scripts/zammad-setup.sh                   ║
║    <base_url> <api_token>                       ║
║                                                  ║
║  Example:                                        ║
║  bash scripts/zammad-setup.sh \                 ║
║    https://zammad.example.com abc123token        ║
║                                                  ║
║  Or set env vars:                                ║
║    export ZAMMAD_URL=https://zammad.example.com  ║
║    export ZAMMAD_TOKEN=your_api_token            ║
╚══════════════════════════════════════════════════╝
SETUP
    exit 1
  fi

  # Strip trailing slash from URL
  ZAMMAD_URL="${ZAMMAD_URL%/}"
}

# ─── HTTP Helpers ────────────────────────────────────────

# GET request: _zammad_get "/api/v1/users" ["extra_params"]
_zammad_get() {
  local endpoint="$1"
  local extra="${2:-}"
  local url="${ZAMMAD_URL}${endpoint}"
  if [ -n "$extra" ]; then
    if [[ "$url" == *"?"* ]]; then
      url="${url}&${extra}"
    else
      url="${url}?${extra}"
    fi
  fi
  curl -sf --max-time "$ZAMMAD_TIMEOUT" \
    -H "Authorization: Token token=${ZAMMAD_TOKEN}" \
    -H "Content-Type: application/json" \
    "$url" 2>&1
}

# POST request: _zammad_post "/api/v1/tickets" '{"title":"..."}'
_zammad_post() {
  local endpoint="$1"
  local body="$2"
  curl -sf --max-time "$ZAMMAD_TIMEOUT" \
    -X POST "${ZAMMAD_URL}${endpoint}" \
    -H "Authorization: Token token=${ZAMMAD_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$body" 2>&1
}

# PUT request: _zammad_put "/api/v1/tickets/123" '{"state":"open"}'
_zammad_put() {
  local endpoint="$1"
  local body="$2"
  curl -sf --max-time "$ZAMMAD_TIMEOUT" \
    -X PUT "${ZAMMAD_URL}${endpoint}" \
    -H "Authorization: Token token=${ZAMMAD_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$body" 2>&1
}

# ─── JSON Helpers ────────────────────────────────────────

# Safely JSON-encode a string value
_zammad_json_encode() {
  python3 -c "import json,sys;print(json.dumps(sys.argv[1]))" "$1"
}

# Pretty-print JSON with python3
_zammad_json_pp() {
  python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(json.dumps(data, indent=2, ensure_ascii=False))
except:
    sys.exit(1)
"
}
