#!/usr/bin/env bash
# Create a Zammad ticket (always requires owner assignment)
# Usage: zammad-ticket-create.sh <title> <body> [owner_id_or_email] [group] [priority] [customer_email] [state]
#
# Args:
#   title          - Ticket title (required)
#   body           - Ticket description/first article body (required)
#   owner          - Owner user ID or email (required for assignment)
#   group          - Group name (default: "Users")
#   priority       - "1 low" | "2 normal" | "3 high" (default: "2 normal")
#   customer_email - Customer email (optional, defaults to API user)
#   state          - "new" | "open" | "pending reminder" | "closed" (default: "new")
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

TITLE="${1:?Usage: zammad-ticket-create.sh <title> <body> [owner] [group] [priority] [customer] [state]}"
BODY_TEXT="${2:?Missing ticket body/description}"
OWNER="${3:-}"
GROUP="${4:-Users}"
PRIORITY="${5:-2 normal}"
CUSTOMER="${6:-}"
STATE="${7:-new}"

BODY=$(python3 -c "
import json, sys

ticket = {
    'title': sys.argv[1],
    'group': sys.argv[2],
    'state': sys.argv[5],
    'priority': sys.argv[4],
    'article': {
        'subject': sys.argv[1],
        'body': sys.argv[6],
        'type': 'note',
        'internal': False
    }
}

# Owner: numeric ID or email
owner = sys.argv[3]
if owner:
    if owner.isdigit():
        ticket['owner_id'] = int(owner)
    else:
        ticket['owner'] = owner

# Customer
customer = sys.argv[7]
if customer:
    ticket['customer'] = customer

print(json.dumps(ticket))
" "$TITLE" "$GROUP" "$OWNER" "$PRIORITY" "$STATE" "$BODY_TEXT" "$CUSTOMER")

RESPONSE=$(_zammad_post "/api/v1/tickets" "$BODY") || {
  echo "ERROR: Failed to create ticket." >&2
  echo "$RESPONSE" >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
t = json.load(sys.stdin)
if 'error' in t:
    print(f\"ERROR: {t['error']}\", file=sys.stderr)
    sys.exit(1)
print(f\"Ticket created successfully:\")
print(f\"  ID:       #{t.get('id')}\")
print(f\"  Number:   {t.get('number','')}\")
print(f\"  Title:    {t.get('title')}\")
print(f\"  State:    {t.get('state','') or t.get('state_id','')}\")
print(f\"  Priority: {t.get('priority','') or t.get('priority_id','')}\")
print(f\"  Group:    {t.get('group','') or t.get('group_id','')}\")
print(f\"  Owner:    {t.get('owner','') or t.get('owner_id','unassigned')}\")
print(f\"  Customer: {t.get('customer','') or t.get('customer_id','')}\")
" 2>&1
