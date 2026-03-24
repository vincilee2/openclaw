#!/usr/bin/env bash
# List Zammad users (paginated)
# Usage: zammad-user-list.sh [page] [per_page]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

PAGE="${1:-1}"
PER_PAGE="${2:-25}"

RESPONSE=$(_zammad_get "/api/v1/users?page=${PAGE}&per_page=${PER_PAGE}&expand=true") || {
  echo "ERROR: Failed to list users." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
users = json.load(sys.stdin)
if not isinstance(users, list):
    users = [users] if users else []
page = int(sys.argv[1])
per_page = int(sys.argv[2])
print(f'Users (page {page}, {per_page}/page, showing {len(users)}):')
print()
role_map = {1: 'Admin', 2: 'Agent', 3: 'Customer'}
for u in users:
    roles = u.get('role_ids', [])
    role_names = [role_map.get(r, str(r)) for r in roles]
    active = '✓' if u.get('active', True) else '✗'
    dept = u.get('department', '') or ''
    note = u.get('note', '') or ''
    print(f\"  [{u['id']}] {active} {u.get('firstname','')} {u.get('lastname','')} <{u.get('email','')}>  [{', '.join(role_names)}]\")
    if dept:
        print(f\"       Department: {dept}\")
    if note:
        note_short = note[:80] + ('...' if len(note) > 80 else '')
        print(f\"       Note: {note_short}\")
    print()
if len(users) == per_page:
    print(f'More results may exist. Use: zammad-user-list.sh {page + 1} {per_page}')
" "$PAGE" "$PER_PAGE" 2>&1
