#!/usr/bin/env bash
# Search Zammad users by name/email
# Usage: zammad-user-search.sh <query> [limit]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

QUERY="${1:?Usage: zammad-user-search.sh <query> [limit]}"
LIMIT="${2:-20}"

SAFE_QUERY=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$QUERY")

RESPONSE=$(_zammad_get "/api/v1/users/search?query=${SAFE_QUERY}&limit=${LIMIT}&expand=true") || {
  echo "ERROR: Failed to search users." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
users = json.load(sys.stdin)
if not isinstance(users, list):
    users = [users] if users else []
if not users:
    print('No users found.')
    sys.exit(0)
print(f'Found {len(users)} user(s):')
print()
for u in users:
    roles = u.get('role_ids', [])
    role_map = {1: 'Admin', 2: 'Agent', 3: 'Customer'}
    role_names = [role_map.get(r, str(r)) for r in roles]
    groups = u.get('group_ids', {})
    dept = u.get('department', '') or ''
    note = u.get('note', '') or ''
    print(f\"  [{u['id']}] {u.get('firstname','')} {u.get('lastname','')} <{u.get('email','')}>  [{', '.join(role_names)}]\")
    if dept:
        print(f\"       Department: {dept}\")
    if note:
        note_short = note[:100] + ('...' if len(note) > 100 else '')
        print(f\"       Note: {note_short}\")
    if groups:
        print(f\"       Groups: {groups}\")
    print()
" 2>&1
