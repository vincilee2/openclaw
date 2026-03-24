#!/usr/bin/env bash
# Get Zammad user details by ID
# Usage: zammad-user-get.sh <user_id>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

USER_ID="${1:?Usage: zammad-user-get.sh <user_id>}"

RESPONSE=$(_zammad_get "/api/v1/users/${USER_ID}?expand=true") || {
  echo "ERROR: Failed to get user #${USER_ID}." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
u = json.load(sys.stdin)
if 'error' in u:
    print(f\"ERROR: {u['error']}\", file=sys.stderr)
    sys.exit(1)
role_map = {1: 'Admin', 2: 'Agent', 3: 'Customer'}
roles = u.get('role_ids', [])
role_names = [role_map.get(r, str(r)) for r in roles]
print(f\"User #{u['id']}:\")
print(f\"  Name:       {u.get('firstname','')} {u.get('lastname','')}\")
print(f\"  Email:      {u.get('email','')}\")
print(f\"  Login:      {u.get('login','')}\")
print(f\"  Roles:      {', '.join(role_names)} (IDs: {roles})\")
print(f\"  Active:     {u.get('active', 'N/A')}\")
print(f\"  Department: {u.get('department','') or '-'}\")
print(f\"  Note:       {u.get('note','') or '-'}\")
print(f\"  Groups:     {u.get('group_ids', {})}\")
print(f\"  Created:    {u.get('created_at','')}\")
print(f\"  Updated:    {u.get('updated_at','')}\")
" 2>&1
