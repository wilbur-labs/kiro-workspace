# dogfood-todo-api — Session Recovery

> Read this file at session start to understand current state.
> Last updated: 2026-05-24

## Purpose (read this first)

This task is the **M1 end-to-end verification harness**. The "product" — a tiny three-unit Todo API — exists to exercise every M1 gate. The actual verification checklist is below; the source code under `src/` (gitignored, your fork generates it locally) is incidental.

Before running `kiro-cli chat --agent dogfood-todo-api`, do this:

1. Edit `tasks/dogfood-todo-api/task.yaml` and replace `<edit-me-with-your-fork-path>` with your absolute clone path (the file has a banner explaining why).
2. Read `vision.md` and `tech-env.md` end-to-end — they intentionally drive the agent toward specific shapes that exercise the gates.
3. When the agent's first message proposes AI-DLC depth, you should see it pick **standard** (new-system shape, per `.kiro/skills/aidlc-auto-trigger.md`). If it picks anything else, that's row #4 of the checklist failing.

## Current State

- Branch: `dogfood/<your local branch>` — dogfood code is local-only, do not push
- Status: scaffold landed, dogfood run not yet executed by this fork

## Current AI-DLC Stage

> Update each time you pause. The agentSpawn hook also reads `aidlc-docs/aidlc-state.md`.

- Phase: `n/a` (not yet started)
- Stage: `n/a`
- Unit: `n/a`
- Next unchecked step: start `kiro-cli chat --agent dogfood-todo-api`, expect AI-DLC depth proposal

## M1 Verification Checklist

Each row maps to one M0 audit candidate. **Bold** rows are the ones dogfood is built to verify; the rest were already verified at PR-merge time but are listed here for completeness.

### Already verified by per-PR smoke (just confirm on this fork)

- [ ] **#3 broken refs** — fresh fork after `scripts/init-workspace.sh`: `.kiro/shared/SHARED-CONTEXT.md` and `.kiro/learned/LEARNED.md` exist, no silent hook failure. Delete one, re-spawn agent, hook prints the `⚠ ... run scripts/init-workspace.sh` hint instead of failing silently.
- [ ] **#5 AI-DLC stage in RESUME + hook** — after AI-DLC runs for a while, this RESUME's `## Current AI-DLC Stage` reflects where it paused; agentSpawn hook output includes `aidlc-docs/aidlc-state.md | head -20`.
- [ ] **#6.a vision/tech-env tpl + `--no-aidlc`** — `scripts/new-task.sh foo /tmp/foo` produces `foo/vision.md` + `foo/tech-env.md`; `scripts/new-task.sh --no-aidlc bar /tmp/bar` skips them. (Already smoked in M1.2 PR.)
- [ ] **#6.b task.yaml single source of truth** — `task.yaml` is the first file the agentSpawn hook prints; `RESUME.md` Key Info and `prompt.md` Environment point to it instead of duplicating paths.
- [ ] **#7 prompt persona / decision / style** — `.kiro/prompts/dogfood-todo-api.md` has all three sections; edit one section, re-spawn agent, change is reflected.
- [ ] **#8 update-aidlc preserve local mods** — inject one local line in `.kiro/aws-aidlc-rule-details/common/welcome-message.md`; `scripts/update-aidlc.sh --dry-run v0.1.8` surfaces the diff; normal run refuses with exit 2. (Already smoked in M1.1 PR.)
- [ ] **#11 memory layering split** — say "Todo table PK uses uuid" → agent writes to `tasks/dogfood-todo-api/learned.md`. Say "FastAPI Depends doesn't fire for WebSocket — use middleware" → agent writes to `.kiro/learned/LEARNED.md` with a "Why cross-task" line.

### Verified by this dogfood run (the bold-faced four)

- [ ] **#1 Interface Contracts freeze (M1.3)** — at the end of inception, three contract files appear under `aidlc-docs/inception/application-design/contracts/`:
  - [ ] `auth.yaml` (OpenAPI) — login + token-verify endpoints
  - [ ] `todo-crud.yaml` (OpenAPI) — todo CRUD endpoints
  - [ ] `notification.py` (Pydantic) — notify(user_id, message) call signature
  - [ ] Agent runs cross-unit consumer-perspective review and asks user to approve the set before transitioning to CONSTRUCTION.
- [ ] **#2 Cross-unit smoke + Build & Test must-run (M1.3)**:
  - [ ] After `todo-crud` code-gen step 7 completes, agent generates `src/tests/smoke/test_todo_against_auth.py` (or equivalent) that hits the **real** `auth` service for a token — not a mock — and runs it as part of closing step 7.
  - [ ] Reviewer manually breaks `todo-crud`'s contract handling (e.g. renames the JWT field it expects). Smoke fails, step 7 is blocked, agent classifies as `bug` CR.
  - [ ] Build & Test stage runs the full pytest suite (`uv run pytest`) — actual test execution, captured to `aidlc-docs/construction/build-and-test/test-run-<timestamp>.log` with pass/fail counts reported.
- [ ] **#4 AI-DLC auto-trigger (M1.4)** — fresh `kiro-cli chat --agent dogfood-todo-api` session, agent's first message proposes `standard` depth with one-line rationale. (If you say `n`, agent must not re-propose.)
- [ ] **#10 Change Management CR-log + phase gate (M1.2.5)**:
  - [ ] Mid-construction, say "顺手加 CSV 导出" — agent captures as `CR-N | OPEN | UNCLASSIFIED` row in `aidlc-docs/change-requests.md` without breaking flow.
  - [ ] Attempt to approve construction phase with OPEN CR — agent refuses, lists the CR, prompts for triage.
  - [ ] Classify CR-N as `creep / accept` — agent requires `vision.md` + `requirements.md` updates **before** continuing; `Propagated To` filled in.
  - [ ] All CRs resolved → construction approval proceeds.

### Will be verified once M1.9 lands

- [ ] **#9 Code-quality gate (M1.9 — pending)** — when M1.9 PR ships, re-run this dogfood and add row(s) here per its CHANGELOG entry. Probable acceptance: (a) reviewer-agent surfaces at least one semantic-duplication finding the linter missed, (b) `tech-env.md` quality-tools section is honored by `Build & Test`.

## What to do if a row fails

Don't silently fix and re-run. Each failure is itself a finding:

1. Note the row number + the actual observed behavior in this RESUME's **Findings** section below.
2. If it's a steering / scaffold defect — raise an issue on `wilbur-labs/kiro-workspace-template` (link the row). Don't tweak the dogfood vision/tech-env to make the row pass; that masks the defect.
3. If it's a "row written wrong" defect (the expectation was unrealistic) — raise an issue + propose a PR to fix the row text.

## Findings

> Empty until a dogfood run produces them. One bullet per failure, with row number + observed behavior + link to issue.

(none yet)

## AI-DLC Artifacts

Generated under `tasks/dogfood-todo-api/aidlc-docs/` (gitignored, regenerable). Source of truth while running: `aidlc-docs/aidlc-state.md`.

## Related

- `vision.md` — Todo-API scope (intentionally tiny; exists to drive the gates)
- `tech-env.md` — Python + FastAPI + SQLite stack
- `.kiro/steering/{interface-contracts,cross-unit-smoke,change-management}.md` — the gates being verified
- `.kiro/skills/{aidlc-auto-trigger,raise-cr,memory-layering}.md` — the skills exercised
