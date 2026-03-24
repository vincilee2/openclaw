---
name: zammad
description: "Zammad helpdesk ticket system management via REST API. Manage users (create, search, list, view, update) and tickets (create with owner assignment, search, view details with messages, update state/priority/owner, add notes). Use when: user mentions zammad, helpdesk, support ticket, work order, ticket system, create ticket, assign ticket, search tickets, manage support users, or any ticket/issue tracking operations."
---

# Zammad Helpdesk Management

Manage users and tickets on a self-hosted Zammad instance via REST API. Pure bash + curl, zero dependencies.

## First Time Setup (REQUIRED)

```bash
bash {baseDir}/scripts/zammad-setup.sh <base_url> <api_token>
# Example:
bash {baseDir}/scripts/zammad-setup.sh https://zammad.example.com abc123token

# View config:
bash {baseDir}/scripts/zammad-setup.sh --show

# Reset:
bash {baseDir}/scripts/zammad-setup.sh --reset
```

Config persists in `~/.zammad-config`. Can also use env vars: `ZAMMAD_URL`, `ZAMMAD_TOKEN`.

**IMPORTANT**: When this skill triggers and no config exists, run setup first. Ask user for URL and token if not known.

## User Management

### Create User
```bash
bash {baseDir}/scripts/zammad-user-create.sh <email> [firstname] [lastname] [role]
# role: customer (default) | agent | admin
```

### Search Users
```bash
bash {baseDir}/scripts/zammad-user-search.sh <query> [limit]
# Searches name, email, login, note fields
```

### List Users
```bash
bash {baseDir}/scripts/zammad-user-list.sh [page] [per_page]
```

### Get User Details
```bash
bash {baseDir}/scripts/zammad-user-get.sh <user_id>
```

### Update User
```bash
bash {baseDir}/scripts/zammad-user-update.sh <user_id> '<json_fields>'
# Example: zammad-user-update.sh 5 '{"department":"Engineering","note":"Backend dev"}'
```

## Ticket Management

### Create Ticket (with Owner Assignment)

```bash
bash {baseDir}/scripts/zammad-ticket-create.sh <title> <body> [owner] [group] [priority] [customer] [state]
```

**Owner assignment is a key workflow.** Follow this logic:

1. **User provides owner ID or email** → pass directly as 3rd arg
2. **User provides a name/keyword** → first run `zammad-user-search.sh` to find matching users, confirm the right one, then create ticket with their ID/email
3. **No owner specified** → run `zammad-user-list.sh` to show available agents, present the list with their roles/departments/notes, let the user (or use context) pick the best match, then create the ticket

Example flow when owner is ambiguous:
```bash
# Step 1: Search for potential owners
bash {baseDir}/scripts/zammad-user-search.sh "engineering"
# Step 2: Pick the right user from results, then create
bash {baseDir}/scripts/zammad-ticket-create.sh "Bug in login" "Login page returns 500" 5 "Users" "3 high"
```

Priority values: `"1 low"`, `"2 normal"` (default), `"3 high"`
State values: `"new"` (default), `"open"`, `"pending reminder"`, `"pending close"`, `"closed"`

### Search Tickets
```bash
bash {baseDir}/scripts/zammad-ticket-search.sh <query> [limit]
```

Query uses Elasticsearch/Lucene syntax:
- `"login error"` — keyword search
- `"state:open"` — by state
- `"owner.email:user@example.com"` — by owner
- `"state:open AND priority_id:3"` — combined filters

### View Ticket Details (with all messages)
```bash
bash {baseDir}/scripts/zammad-ticket-get.sh <ticket_id>
```
Returns ticket metadata + all articles/messages chronologically.

### Update Ticket
```bash
bash {baseDir}/scripts/zammad-ticket-update.sh <ticket_id> '<json_fields>'
```

Common updates:
```bash
# Change state
zammad-ticket-update.sh 123 '{"state":"open"}'
# Reassign owner
zammad-ticket-update.sh 123 '{"owner":"newagent@example.com"}'
# Change priority + group
zammad-ticket-update.sh 123 '{"priority":"3 high","group":"Engineering"}'
```

### List Tickets
```bash
bash {baseDir}/scripts/zammad-ticket-list.sh [page] [per_page]
```

### Add Note to Ticket
```bash
bash {baseDir}/scripts/zammad-ticket-add-article.sh <ticket_id> <body> [subject] [internal: true|false]
```

## API Reference

For full endpoint details, field names, and Lucene query syntax, see [references/api-endpoints.md](references/api-endpoints.md).
