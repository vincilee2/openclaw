#!/usr/bin/env bash
# Update a Zammad ticket (state, owner, priority, etc.)
# Usage: zammad-ticket-update.sh <ticket_id> <json_fields>
#
# Examples:
#   zammad-ticket-update.sh 123 '{"state":"open"}'
#   zammad-ticket-update.sh 123 '{"owner_id":5}'
#   zammad-ticket-update.sh 123 '{"owner":"lisi@example.com","priority":"3 high"}'
#   zammad-ticket-update.sh 123 '{"group":"Engineering","state":"open"}'
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

TICKET_ID="${1:?Usage: zammad-ticket-update.sh <ticket_id> '<json_fields>'}"
FIELDS="${2:?Missing JSON fields to update}"

RESPONSE=$(_zammad_put "/api/v1/tickets/${TICKET_ID}" "$FIELDS") || {
  echo "ERROR: Failed to update ticket #${TICKET_ID}." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
t = json.load(sys.stdin)
if 'error' in t:
    print(f\"ERROR: {t['error']}\", file=sys.stderr)
    sys.exit(1)
owner = t.get('owner', '') or t.get('owner_id', 'unassigned')
state = t.get('state', '') or t.get('state_id', '')
priority = t.get('priority', '') or t.get('priority_id', '')
print(f\"Ticket #{t['id']} updated:\")
print(f\"  Title:    {t.get('title','')}\")
print(f\"  State:    {state}\")
print(f\"  Priority: {priority}\")
print(f\"  Owner:    {owner}\")
print(f\"  Group:    {t.get('group','') or t.get('group_id','')}\")
" 2>&1
