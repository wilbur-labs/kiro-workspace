# Vision: dogfood-todo-api

> This is the M1 end-to-end verification harness. The "product" is intentionally tiny — what matters is that running AI-DLC over this vision exercises all M1 gates (#1 contracts, #2 cross-unit smoke + Build & Test, #4 auto-trigger, #10 CR-log + phase approval, #11 memory split). Treat this as a fixture, not a candidate for real users.

## Executive Summary

dogfood-todo-api is a single-user Todo REST API decomposed into exactly three units (`auth`, `todo-crud`, `notification`). It exists so that a fork of `wilbur-labs/kiro-workspace-template` can rerun the M1 verification pass end-to-end and confirm every gate fires. The expected outcome is a runnable Python service (under `tasks/dogfood-todo-api/src/`) plus an auditable trail of CRs, contracts, smoke runs, and Build & Test logs that a reviewer can inspect.

## Features In Scope (MVP)

- **auth unit** — username + password login returning a short-lived JWT; token-verify endpoint for the other units to call.
- **todo-crud unit** — for the authenticated user: create / list / get-by-id / update / delete todo items. Each todo has `id`, `title`, `description`, `due_at`, `done`, `owner_user_id`.
- **notification unit** — when a todo's `due_at` is within the next hour and `done=false`, send one reminder via a stub `notify(user_id, message)` function (no real email; print to stdout is fine for dogfood).
- A `docker-compose.yml` (or equivalent) that starts all three units locally so the smoke tests in M1.3 #2 can hit them.
- pytest test suite with unit tests per unit and cross-unit smoke tests under `tests/smoke/`.

## Features Explicitly Out of Scope (MVP)

- User registration / password reset (Phase 2) — dogfood ships with one hardcoded test user.
- Real email / push / SMS delivery (Phase 2) — notification unit stops at the in-process stub call.
- Multi-user sharing of todos (Phase 3) — every todo strictly belongs to one user.
- Pagination, search, filtering of the todo list (Phase 3) — list endpoint returns everything for the user.
- Production deployment, IaC, CI pipelines (no plan) — dogfood runs on the developer's machine only.
- Frontend / web UI (no plan) — REST endpoints only.
- Authorization beyond "the JWT belongs to the same user" (no plan).

## Target Users

- **The template fork operator.** Anyone forking `wilbur-labs/kiro-workspace-template` who wants to confirm M1 gates work before relying on them for real work.
- **The kiro-workspace-template maintainer.** Reruns dogfood when shipping a new M-milestone to catch regressions in steering.

## Key Success Metrics

- **All M1 gates fire** during the run. The 11-row checklist in `tasks/dogfood-todo-api/RESUME.md` is the source of truth — each row must end ✅ after the dogfood pass.
- **Cross-unit smoke catches a deliberate contract break.** Reviewer manually mis-types one field in `todo-crud`'s contract; smoke under `tests/smoke/test_todo_against_auth.py` (or equivalent) must fail and block closing code-gen step 7.
- **Phase approval blocks an OPEN CR.** Reviewer manually adds an OPEN CR mid-construction; attempting to approve construction must list the CR and refuse.
- **AI-DLC auto-trigger proposes the correct depth.** A fresh agent reading this vision should propose `standard` depth (new-system shape) — not `minimal`, not `comprehensive`.

## Open Questions

- Where does the JWT signing key live for the dogfood run? Suggested default: a hardcoded constant in `auth/config.py` with a comment "dogfood-only — never copy this pattern into a real app." If you want to demonstrate the secret-management portion of tech-env.md, swap to env-var here.
- Should the notification unit poll, or be invoked by a cron-like loop, or be triggered by `todo-crud` after create/update? Default for dogfood: a simple background asyncio task that scans every 30 seconds. Pick whichever lets cross-unit smoke be simplest to write.
- Is property-based testing (hypothesis) in scope, or only example-based pytest? Default: example-based for dogfood (smaller surface to verify).
