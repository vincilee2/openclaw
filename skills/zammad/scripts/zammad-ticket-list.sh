#!/usr/bin/env bash
# List Zammad tickets (paginated)
# Usage: zammad-ticket-list.sh [page] [per_page]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

PAGE="${1:-1}"
PER_PAGE="${2:-25}"

RESPONSE=$(_zammad_get "/api/v1/tickets?page=${PAGE}&per_page=${PER_PAGE}&expand=true") || {
  echo "ERROR: Failed to list tickets." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
tickets = json.load(sys.stdin)
if not isinstance(tickets, list):
    tickets = [tickets] if tickets else []
page = int(sys.argv[1])
per_page = int(sys.argv[2])
print(f'Tickets (page {page}, {per_page}/page, showing {len(tickets)}):')
print()
for t in tickets:
    owner = t.get('owner', '') or t.get('owner_id', 'unassigned')
    state = t.get('state', '') or t.get('state_id', '')
    priority = t.get('priority', '') or t.get('priority_id', '')
    customer = t.get('customer', '') or t.get('customer_id', '')
    print(f\"  #{t.get('id','')} [{state}] [{priority}] {t.get('title','')}\")
    print(f\"       Owner: {owner}  Customer: {customer}\")
    print(f\"       Updated: {t.get('updated_at','')}\")
    print()
if len(tickets) == per_page:
    print(f'More results may exist. Use: zammad-ticket-list.sh {page + 1} {per_page}')
" "$PAGE" "$PER_PAGE" 2>&1
