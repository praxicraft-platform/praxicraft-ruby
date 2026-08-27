# Changelog

## [1.0.0] — 2026-08-27

### Breaking

- Rename assessment task methods from `list_cases` / `attach_cases` / `replace_cases` / `remove_case` to `list_tasks` / `attach_tasks` / `replace_tasks` / `remove_task`.
- Wire paths use `/tasks/` instead of `/cases/`; JSON keys use `tasks`, `task_id`, and `assessment_task_id`.

## [0.1.1] — 2026-08-21

### Changed

- Align error mapping and retry behaviour with the Node SDK (status-based exceptions, 8s `Retry-After` cap).
- Fix path-segment encoding so spaces become `%20`.

## [0.1.0] — 2026-08-21

### Added

- Initial Assess Public API SDK.
- `Client` with Bearer API-key auth (`PRAXICRAFT_API_KEY` / `PRAXICRAFT_API_BASE_URL`).
- Automatic retries on `429` / `5xx` / transport errors (default 2), honouring `Retry-After`.
- Typed / mapped errors from `{ error: { code, message } }`.
- Resources: org, assessments, invites, results, webhooks, pipelines.
- Webhook signature helper for `X-Praxicraft-Signature`.
