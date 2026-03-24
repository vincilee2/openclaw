# Zammad API Endpoint Reference

## Authentication

All requests require:
- Header: `Authorization: Token token={api_token}`
- Header: `Content-Type: application/json`

Append `?expand=true` to GET requests for full field names instead of IDs.

## Default IDs

### Roles
| role_id | Name | Description |
|---------|------|-------------|
| 1 | Admin | System configuration |
| 2 | Agent | Ticket handling |
| 3 | Customer | End user (default signup) |

### Ticket States
| state_id | Name |
|----------|------|
| 1 | new |
| 2 | open |
| 3 | pending reminder |
| 4 | pending close |
| 5 | merged |
| 6 | removed |
| 7 | closed |

### Ticket Priorities
| priority_id | Name |
|-------------|------|
| 1 | 1 low |
| 2 | 2 normal |
| 3 | 3 high |

## User Endpoints

### Create User
```
POST /api/v1/users
{
  "email": "user@example.com",
  "login": "user@example.com",
  "firstname": "First",
  "lastname": "Last",
  "password": "optional",
  "role_ids": [3],
  "group_ids": {"1": ["full"]},  // for agents
  "department": "Engineering",
  "note": "Description of this user"
}
```
Required: `email`, `role_ids`. Permission: `admin.user`.

### List Users
```
GET /api/v1/users?page=1&per_page=25&expand=true
```

### Get User
```
GET /api/v1/users/{id}?expand=true
```

### Update User
```
PUT /api/v1/users/{id}
{any user fields to update}
```

### Search Users
```
GET /api/v1/users/search?query={term}&limit=20&expand=true
```
Searches across name, email, login, note fields.

## Ticket Endpoints

### Create Ticket
```
POST /api/v1/tickets
{
  "title": "Subject",
  "group": "Users",
  "customer": "customer@example.com",
  "owner": "agent@example.com",     // or "owner_id": 5
  "state": "new",
  "priority": "2 normal",
  "article": {
    "subject": "Subject",
    "body": "Description text",
    "type": "note",
    "internal": false
  }
}
```
Required: `title`, `group`, `article.body`.
Optional: `owner`/`owner_id`, `customer`, `state`, `priority`, `tags`, custom fields.

### Create on Behalf of Customer
Add header: `X-On-Behalf-Of: customer@example.com`

### List Tickets
```
GET /api/v1/tickets?page=1&per_page=25&expand=true
```

### Get Ticket
```
GET /api/v1/tickets/{id}?expand=true
```

### Update Ticket
```
PUT /api/v1/tickets/{id}
{any ticket fields: state, owner_id, priority, group, etc.}
```

### Search Tickets
```
GET /api/v1/tickets/search?query={lucene_query}&limit=20&expand=true
```

Lucene query examples:
- `state:open` — filter by state
- `owner.email:agent@example.com` — by owner
- `customer.email:user@example.com` — by customer
- `priority_id:3` — by priority
- `created_at:>2026-01-01` — by date
- `state:open AND priority_id:3` — combined

## Article Endpoints

### Get Articles for Ticket
```
GET /api/v1/ticket_articles/by_ticket/{ticket_id}
```

### Create Article (add note/reply)
```
POST /api/v1/ticket_articles
{
  "ticket_id": 123,
  "subject": "Follow-up",
  "body": "Message text",
  "type": "note",
  "internal": false
}
```

## Tags

### Add Tag
```
POST /api/v1/tags/add
{"object": "Ticket", "o_id": 123, "item": "urgent"}
```

### Get Tags
```
GET /api/v1/tags?object=Ticket&o_id=123
```

## Other Useful Endpoints

| Resource | Endpoint |
|----------|----------|
| Ticket States | `GET /api/v1/ticket_states` |
| Ticket Priorities | `GET /api/v1/ticket_priorities` |
| Groups | `GET /api/v1/groups` |
| Roles | `GET /api/v1/roles` |
| Object Manager | `GET /api/v1/object_manager_attributes` |
