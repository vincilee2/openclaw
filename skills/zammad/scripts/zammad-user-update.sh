#!/usr/bin/env bash
# Update a Zammad user
# Usage: zammad-user-update.sh <user_id> <json_fields>
# Example: zammad-user-update.sh 5 '{"firstname":"New","department":"Eng"}'
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

USER_ID="${1:?Usage: zammad-user-update.sh <user_id> '<json_fields>'}"
FIELDS="${2:?Missing JSON fields to update}"

RESPONSE=$(_zammad_put "/api/v1/users/${USER_ID}" "$FIELDS") || {
  echo "ERROR: Failed to update user #${USER_ID}." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
u = json.load(sys.stdin)
if 'error' in u:
    print(f\"ERROR: {u['error']}\", file=sys.stderr)
    sys.exit(1)
print(f\"User #{u['id']} updated:\")
print(f\"  Name:  {u.get('firstname','')} {u.get('lastname','')}\")
print(f\"  Email: {u.get('email','')}\")
print(f\"  Roles: {u.get('role_ids', [])}\")
" 2>&1
