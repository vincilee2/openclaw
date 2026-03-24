#!/usr/bin/env bash
# Add a note/article to an existing ticket
# Usage: zammad-ticket-add-article.sh <ticket_id> <body> [subject] [internal: true|false]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"
_zammad_ensure_config

TICKET_ID="${1:?Usage: zammad-ticket-add-article.sh <ticket_id> <body> [subject] [internal]}"
BODY_TEXT="${2:?Missing article body}"
SUBJECT="${3:-}"
INTERNAL="${4:-false}"

BODY=$(python3 -c "
import json, sys
article = {
    'ticket_id': int(sys.argv[1]),
    'body': sys.argv[2],
    'type': 'note',
    'internal': sys.argv[4].lower() == 'true'
}
if sys.argv[3]:
    article['subject'] = sys.argv[3]
print(json.dumps(article))
" "$TICKET_ID" "$BODY_TEXT" "$SUBJECT" "$INTERNAL")

RESPONSE=$(_zammad_post "/api/v1/ticket_articles" "$BODY") || {
  echo "ERROR: Failed to add article to ticket #${TICKET_ID}." >&2
  exit 1
}

echo "$RESPONSE" | python3 -c "
import json, sys
a = json.load(sys.stdin)
if 'error' in a:
    print(f\"ERROR: {a['error']}\", file=sys.stderr)
    sys.exit(1)
print(f\"Article added to ticket #{a.get('ticket_id','')}:\")
print(f\"  Article ID: {a.get('id','')}\")
print(f\"  Subject:    {a.get('subject','')}\")
print(f\"  Internal:   {a.get('internal', False)}\")
" 2>&1
