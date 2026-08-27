# Praxicraft Assess Ruby SDK

Official Ruby client for the **[Praxicraft Assess](https://assess.praxicraft.com)** Public API.

Use it to invite candidates, check invite quota, manage webhooks, enroll hiring pipelines, and fetch results from your ATS, backend, or automation scripts.

```bash
gem install praxicraft
```

Until RubyGems publish, install from GitHub:

```ruby
# Gemfile
gem "praxicraft", git: "https://github.com/praxicraft-platform/praxicraft-ruby.git"
```

**Requires Ruby 3.1+.** Full API reference: [docs.praxicraft.com/sdks/ruby](https://docs.praxicraft.com/sdks/ruby)

## Table of Contents

- [Authentication](#authentication)
- [Quickstart](#quickstart)
- [What you can do](#what-you-can-do)
  - [Check invite quota before bulk sends](#check-invite-quota-before-bulk-sends)
  - [Bulk invites](#bulk-invites)
  - [Build and activate an assessment via API](#build-and-activate-an-assessment-via-api)
  - [Register and test a webhook](#register-and-test-a-webhook)
  - [Enroll into a hiring pipeline](#enroll-into-a-hiring-pipeline)
  - [Paginate cohort results](#paginate-cohort-results)
  - [Verify webhook signatures](#verify-webhook-signatures)
- [Errors](#errors)
- [Requirements & support](#requirements--support)
- [License](#license)

---

## Authentication

Create an organisation API key in Assess:

**Assess → Developer → API Keys** → create key → copy `ct_live_…` (shown once).

```bash
export PRAXICRAFT_API_KEY="ct_live_xxxxxxxxxxxxxxxx"
```

Or pass the key when constructing the client:

```ruby
require "praxicraft"

client = Praxicraft::Client.new(api_key: "ct_live_xxxxxxxxxxxxxxxx")
```

Optional: override the API host with `PRAXICRAFT_API_BASE_URL` or `Praxicraft::Client.new(base_url: "...")`.
Default host: `https://assess.praxicraft.com`.

Never commit API keys. Prefer environment variables or a secrets manager.

Scopes and rotation: [Authentication](https://docs.praxicraft.com/authentication)

---

## Quickstart

```ruby
require "praxicraft"

client = Praxicraft::Client.new # reads PRAXICRAFT_API_KEY

page = client.assessments.list
page.fetch("results", []).each do |assessment|
  puts "#{assessment["slug"]} #{assessment["status"]}"
end

# Invite a candidate (idempotent on email — safe to retry)
invite = client.invites.create(
  "senior-backend-screen",
  email: "candidate@example.com",
  name: "Jane Doe",
  send_email: true
)
puts "#{invite["invite_token"]} #{invite["invite_url"]}"

result = client.results.retrieve(invite["invite_token"])
p result
```

Responses are **flat JSON** (same shape as the Public API — no `{ "data": … }` wrapper).

---

## What you can do

| Resource | Common methods |
|----------|----------------|
| `client.org` | `retrieve`, `stats` |
| `client.assessments` | `list`, `retrieve`, `create`, `update`, `activate`, `list_tasks`, `attach_tasks`, `replace_tasks`, `remove_task` |
| `client.invites` | `create`, `bulk_create`, `list`, `retrieve`, `remind`, `cancel` |
| `client.results` | `list`, `retrieve`, `iter_all` |
| `client.webhooks` | `list`, `create`, `retrieve`, `update`, `delete`, `test`, `deliveries` |
| `client.pipelines` | `list`, `retrieve`, `enroll`, `bulk_enroll`, `list_enrollments`, `get_enrollment` |
| `Praxicraft::Webhooks.verify_signature` | Verify `X-Praxicraft-Signature` on webhook payloads |

All paths target `/api/v1/public/…` on the Assess host.

### Check invite quota before bulk sends

```ruby
org = client.org.retrieve
if (org["invites_remaining"] || 0) < candidates.length
  abort "Not enough invites remaining this month"
end
```

### Bulk invites

```ruby
client.invites.bulk_create(
  "senior-backend-screen",
  [
    { "email" => "a@example.com", "name" => "Alex" },
    { "email" => "b@example.com", "name" => "Blair" }
  ],
  send_email: true
)
```

### Build and activate an assessment via API

```ruby
assessment = client.assessments.create(title: "Backend screen")
client.assessments.attach_tasks(
  assessment["slug"],
  tasks: [{ "task_id" => "<platform-or-org-task-uuid>", "source" => "platform" }]
)
client.assessments.activate(assessment["slug"])
```

### Register and test a webhook

```ruby
hook = client.webhooks.create(
  url: "https://example.com/hooks/praxicraft",
  events: ["assessment.completed", "candidate.passed"]
)
# Store hook["secret_key"] (whsec_…) — shown once
client.webhooks.test(hook["id"])
client.webhooks.update(hook["id"], is_active: true)
```

### Enroll into a hiring pipeline

```ruby
enrollment = client.pipelines.enroll(
  "grad-2025",
  email: "alex@example.com",
  name: "Alex Lee",
  send_email: true
)
status = client.pipelines.get_enrollment(enrollment["enrollment_id"])
```

### Paginate cohort results

```ruby
client.results.iter_all("senior-backend-screen", page_size: 50) do |row|
  puts "#{row["email"]} #{row["score_percentage"]} #{row["passed"]}"
end
```

### Verify webhook signatures

Assess signs the **raw request body** with your webhook secret (`whsec_…`):

```ruby
def handle_webhook(raw_body, signature_header, secret)
  Praxicraft::Webhooks.verify_signature(secret, raw_body, signature_header)
end
```

Header format: `X-Praxicraft-Signature: sha256=<hex>`

Event catalog and payload examples: [Webhooks](https://docs.praxicraft.com/webhooks)

---

## Errors

Public API errors look like:

```json
{
  "error": {
    "code": "INSUFFICIENT_SCOPE",
    "message": "This API key does not have the 'candidates:read' scope."
  }
}
```

The SDK raises typed exceptions. **Branch on `exc.error_code` (or `exc.code`)**, not the message text:

```ruby
begin
  client.invites.create("demo", email: "candidate@example.com")
rescue Praxicraft::ValidationError => exc
  puts exc.error_code, exc.details
rescue Praxicraft::InsufficientScopeError => exc
  puts exc.error_code
rescue Praxicraft::AuthenticationError => exc
  puts exc.error_code
rescue Praxicraft::RateLimitError => exc
  puts exc.retry_after
end
```

Error codes: [Errors](https://docs.praxicraft.com/errors)

---

## Requirements & support

- Ruby **3.1**, **3.2**, or **3.3+**
- Uses stdlib `Net::HTTP` (no extra runtime gems)
- Product docs: [docs.praxicraft.com](https://docs.praxicraft.com)
- Issues: [GitHub Issues](https://github.com/praxicraft-platform/praxicraft-ruby/issues)

---

## License

[MIT](LICENSE)
