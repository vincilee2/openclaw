#!/usr/bin/env bash
# Search Zammad tickets
# Usage: zammad-ticket-search.sh <query> [limit]
#
# Query supports Elasticsearch/Lucene syntax:
#   "login error"                     - keyword search
#   "state:open"                      - by state
#   "owner.email:lisi@example.com"    - by assigned owner
#   "customer.email:user@example.com" - by customer
#   "priority_id:3"                   - by priority (3=high)
#   "created_at:>2026-01-01"          - by date
#   "state:open AND priority_id:3"    - combined
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

QUERY="${1:?Usage: zammad-ticket-search.sh <query> [limit]}"
LIMIT="${2:-20}"

SAFE_QUERY=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$QUERY")

RESPONSE=$(_zammad_get "/api/v1/tickets/search?query=${SAFE_QUERY}&limit=${LIMIT}&expand=true") || {
  echo "ERROR: Failed to search tickets." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
# Handle both array and object with 'tickets' key
if isinstance(data, list):
    tickets = data
elif isinstance(data, dict):
    tickets = data.get('assets', {}).get('Ticket', {})
    if tickets:
        tickets = list(tickets.values())
    else:
        tickets = data.get('tickets', [])
        if tickets and isinstance(tickets[0], int):
            # Only IDs returned, no expand
            print(f'Found {len(tickets)} ticket IDs: {tickets}')
            print('Tip: ensure ?expand=true for full details')
            sys.exit(0)
else:
    tickets = []

if not tickets:
    print('No tickets found.')
    sys.exit(0)

print(f'Found {len(tickets)} ticket(s):')
print()
for t in tickets:
    owner = t.get('owner', '') or t.get('owner_id', 'unassigned')
    state = t.get('state', '') or t.get('state_id', '')
    priority = t.get('priority', '') or t.get('priority_id', '')
    customer = t.get('customer', '') or t.get('customer_id', '')
    print(f\"  #{t.get('id','')} [{state}] [{priority}] {t.get('title','')}\")
    print(f\"       Owner: {owner}  Customer: {customer}\")
    print(f\"       Created: {t.get('created_at','')}  Updated: {t.get('updated_at','')}\")
    print()
" 2>&1
