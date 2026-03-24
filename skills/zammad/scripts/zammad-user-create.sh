#!/usr/bin/env bash
# Create a Zammad user
# Usage: zammad-user-create.sh <email> [firstname] [lastname] [role: customer|agent|admin]
# Default role: customer (role_id=3)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

EMAIL="${1:?Usage: zammad-user-create.sh <email> [firstname] [lastname] [role]}"
FIRSTNAME="${2:-}"
LASTNAME="${3:-}"
ROLE="${4:-customer}"

# Map role name to role_id
case "$ROLE" in
  admin)    ROLE_IDS="[1]" ;;
  agent)    ROLE_IDS="[2]" ;;
  customer) ROLE_IDS="[3]" ;;
  *)        echo "ERROR: Invalid role '$ROLE'. Use: customer, agent, admin" >&2; exit 1 ;;
esac

BODY=$(python3 -c "
import json, sys
obj = {
    'email': sys.argv[1],
    'login': sys.argv[1],
    'role_ids': json.loads(sys.argv[4])
}
if sys.argv[2]: obj['firstname'] = sys.argv[2]
if sys.argv[3]: obj['lastname'] = sys.argv[3]
print(json.dumps(obj))
" "$EMAIL" "$FIRSTNAME" "$LASTNAME" "$ROLE_IDS")

RESPONSE=$(_zammad_post "/api/v1/users" "$BODY") || {
  echo "ERROR: Failed to create user." >&2
  echo "$RESPONSE" >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
u = json.load(sys.stdin)
if 'error' in u:
    print(f\"ERROR: {u['error']}\", file=sys.stderr)
    sys.exit(1)
print(f\"User created successfully:\")
print(f\"  ID:    {u.get('id')}\")
print(f\"  Login: {u.get('login')}\")
print(f\"  Name:  {u.get('firstname','')} {u.get('lastname','')}\")
print(f\"  Email: {u.get('email')}\")
print(f\"  Roles: {u.get('role_ids', [])}\")
" 2>&1
