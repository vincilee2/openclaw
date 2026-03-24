#!/usr/bin/env bash
# Get Zammad ticket details including all articles/messages
# Usage: zammad-ticket-get.sh <ticket_id>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

TICKET_ID="${1:?Usage: zammad-ticket-get.sh <ticket_id>}"

# Get ticket details
TICKET=$(_zammad_get "/api/v1/tickets/${TICKET_ID}?expand=true") || {
  echo "ERROR: Failed to get ticket #${TICKET_ID}." >&2
  exit 1
}

# Get all articles for this ticket
ARTICLES=$(_zammad_get "/api/v1/ticket_articles/by_ticket/${TICKET_ID}?expand=true") || {
  ARTICLES="[]"
}

python3 -c "
import json, sys

t = json.loads(sys.argv[1])
articles = json.loads(sys.argv[2])

if 'error' in t:
    print(f\"ERROR: {t['error']}\", file=sys.stderr)
    sys.exit(1)

owner = t.get('owner', '') or t.get('owner_id', 'unassigned')
state = t.get('state', '') or t.get('state_id', '')
priority = t.get('priority', '') or t.get('priority_id', '')
group = t.get('group', '') or t.get('group_id', '')
customer = t.get('customer', '') or t.get('customer_id', '')

print(f\"Ticket #{t['id']} (#{t.get('number','')})\")
print(f\"{'='*60}\")
print(f\"  Title:    {t.get('title','')}\")
print(f\"  State:    {state}\")
print(f\"  Priority: {priority}\")
print(f\"  Group:    {group}\")
print(f\"  Owner:    {owner}\")
print(f\"  Customer: {customer}\")
print(f\"  Created:  {t.get('created_at','')}\")
print(f\"  Updated:  {t.get('updated_at','')}\")
tags = t.get('tags', '')
if tags:
    print(f\"  Tags:     {tags}\")
print()

if not isinstance(articles, list):
    articles = []

if articles:
    print(f'Articles ({len(articles)}):')
    print(f\"{'─'*60}\")
    for i, a in enumerate(articles, 1):
        internal = ' [INTERNAL]' if a.get('internal') else ''
        sender = a.get('sender', '') or a.get('sender_id', '')
        from_addr = a.get('from', '') or ''
        atype = a.get('type', '') or a.get('type_id', '')
        body = a.get('body', '')
        # Strip HTML tags if present
        if '<' in body:
            import re
            body = re.sub(r'<[^>]+>', '', body).strip()
        if len(body) > 500:
            body = body[:500] + '...'
        print(f\"  [{i}] {a.get('subject','(no subject)')}{internal}\")
        print(f\"      From: {from_addr}  Type: {atype}  Sender: {sender}\")
        print(f\"      Date: {a.get('created_at','')}\")
        attachments = a.get('attachments', [])
        if attachments:
            att_names = [att.get('filename','?') for att in attachments]
            print(f\"      Attachments: {', '.join(att_names)}\")
        print(f\"      Body: {body}\")
        print()
else:
    print('No articles found.')
" "$TICKET" "$ARTICLES" 2>&1
