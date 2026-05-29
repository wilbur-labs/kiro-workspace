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
- Status: scaffold landed + synced with M1.9 (main 98327ec, all M1.1–M1.9 gates present); dogfood run not yet executed by this fork

## Current AI-DLC Stage

> Update each time you pause. The agentSpawn hook also reads `aidlc-docs/aidlc-state.md`.

- Phase: `construction` (verification run complete — intentionally NOT approved into operations; this is a harness, not a real ship)
- Verification run done: 2026-05-24 (real kiro-cli 2.2.0)
- PASS: #4 auto-trigger · #1 contracts+freeze · #2 smoke happy+build&test · #9 reviewer component · #10 CR-log+phase-gate
- FINDINGS (see ## Findings): #9 reviewer auto-invocation missing · #2 smoke overrides the consumer code under test

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

- [x] **#1 Interface Contracts freeze (M1.3)** ✅ PASS (3 contracts + cross-unit consumer review + freeze gate all verified) — at the end of inception, three contract files appear under `aidlc-docs/inception/application-design/contracts/`:
  - [ ] `auth.yaml` (OpenAPI) — login + token-verify endpoints
  - [ ] `todo-crud.yaml` (OpenAPI) — todo CRUD endpoints
  - [ ] `notification.py` (Pydantic) — notify(user_id, message) call signature
  - [ ] Agent runs cross-unit consumer-perspective review and asks user to approve the set before transitioning to CONSTRUCTION.
- [~] **#2 Cross-unit smoke + Build & Test must-run (M1.3)** ⚠️ happy path + build&test PASS (18 tests, log captured); **fail path = FINDING** (smoke overrides the consumer code under test — see ## Findings):
  - [ ] After `todo-crud` code-gen step 7 completes, agent generates `src/tests/smoke/test_todo_against_auth.py` (or equivalent) that hits the **real** `auth` service for a token — not a mock — and runs it as part of closing step 7.
  - [ ] Reviewer manually breaks `todo-crud`'s contract handling (e.g. renames the JWT field it expects). Smoke fails, step 7 is blocked, agent classifies as `bug` CR.
  - [ ] Build & Test stage runs the full pytest suite (`uv run pytest`) — actual test execution, captured to `aidlc-docs/construction/build-and-test/test-run-<timestamp>.log` with pass/fail counts reported.
- [x] **#4 AI-DLC auto-trigger (M1.4)** ✅ PASS — fresh session, agent proposed `standard` depth with one-line rationale, kept user veto. (If you say `n`, agent must not re-propose.)
- [x] **#10 Change Management CR-log + phase gate (M1.2.5)** ✅ PASS (capture → gate block → triage → release, full loop verified):
  - [ ] Mid-construction, say "顺手加 CSV 导出" — agent captures as `CR-N | OPEN | UNCLASSIFIED` row in `aidlc-docs/change-requests.md` without breaking flow.
  - [ ] Attempt to approve construction phase with OPEN CR — agent refuses, lists the CR, prompts for triage.
  - [ ] Classify CR-N as `creep / accept` — agent requires `vision.md` + `requirements.md` updates **before** continuing; `Propagated To` filled in.
  - [ ] All CRs resolved → construction approval proceeds.

### Verified by this dogfood run (#9 — M1.9 landed on main 98327ec)

- [~] **#9 Code-quality 3-layer gate (M1.9)** ⚠️ reviewer COMPONENT PASS (caught seeded cross-file dup with evidence); **auto-invocation = FINDING** (Layer C never fired — see ## Findings):
  - [ ] **Layer A (prevent)** — during code-gen the agent honors `.kiro/steering/code-quality.md`: when a needed validator/helper already exists it reuses instead of re-implementing (watch it search first), and it declines to add a factory/manager for a single call site. At least one observable instance of each.
  - [ ] **Layer C (detect)** — after a unit's step 7 smoke passes, the `code-quality-reviewer` agent runs and emits the fixed four-block output (verdict / must-fix / suggested / verification), ≤5 findings. Plant a deliberate semantic duplicate (e.g. `todo-crud` re-validates the JWT that `auth` already owns); confirm the reviewer flags it as a cross-file finding **with evidence** — something ruff/eslint would not catch.
  - [ ] A `Request changes` verdict (≥1 Blocker) blocks closing step 7; the finding is fixed or converted to a CR via `change-management.md`.
  - [ ] **Layer B (measure)** — at Build & Test, the `tech-env.md` Code Quality Tooling thresholds are enforced: push one function past cognitive ≤15 (or new-code duplication >3%) and confirm the gate fails, captured in the test-run log.
  - [ ] **Adoptability** — reviewer does not spam nits; with >5 candidate findings it collapses to Blocker/High only.

## What to do if a row fails

Don't silently fix and re-run. Each failure is itself a finding:

1. Note the row number + the actual observed behavior in this RESUME's **Findings** section below.
2. If it's a steering / scaffold defect — raise an issue on `wilbur-labs/kiro-workspace` (link the row). Don't tweak the dogfood vision/tech-env to make the row pass; that masks the defect.
3. If it's a "row written wrong" defect (the expectation was unrealistic) — raise an issue + propose a PR to fix the row text.

## Findings

> One bullet per failure, with row number + observed behavior + link to issue.

- **#9 Layer C (detect)** — code-quality-reviewer agent was never invoked during construction. `.kiro/agents/code-quality-reviewer.json` exists (added in M1.9), but `.kiro/steering/code-quality.md` Layer C says "run the reviewer agent" without defining the invocation mechanism within an AI-DLC flow (what tool/command/delegation protocol does the primary agent use to spawn the reviewer?). The primary agent encountered an undefined call path and **silently skipped** the gate instead of reporting a blocker per `.kiro/skills/raise-cr.md` agent-side self-check. Root causes: (1) steering defines WHAT but not HOW to delegate to another agent mid-flow; (2) agent failed to self-check and raise a CR when it couldn't execute a required gate.

- **#2 cross-unit smoke (fail path)** — smoke does NOT exercise the unit-under-test's real consumer code. `tests/smoke/conftest.py` (`todo_client` fixture) overrides `todo_crud.deps.get_current_user` with a parallel re-implementation defined inside the fixture (`_get_current_user_via_real_auth`). Proof: breaking the real `deps.py` (expected field `user_id`→`sub`) → smoke still PASSES; breaking the fixture's copy → smoke FAILS (KeyError at conftest.py:51). So auth is real (in-process ASGI ✓) but the todo-crud calling code M1.3 #2 means to exercise is mocked out, and the fixture copy is itself semantic duplication of deps.py. AI test anti-pattern: `dependency_overrides` used to make a cross-unit test "runnable" silently replaces the consumer code, defeating the smoke's purpose. `cross-unit-smoke.md` bans mocking the *upstream* unit but does not forbid overriding the *consumer's own* calling code. Fix direction: drive the unit's real dependency (point `AUTH_SERVICE_URL` at an in-process transport / inject the ASGI transport into the real `get_current_user`) instead of overriding `get_current_user` wholesale.

- **#9 reviewer capability (PASS — recorded for completeness)** — invoked directly, `code-quality-reviewer` correctly caught a seeded cross-file semantic duplicate (todo-crud re-implementing auth's `decode_access_token`) as a Blocker WITH evidence (`auth/tokens.py:15-19`), flagged the dead code, downgraded an unprovable point to "needs confirmation", emitted the fixed 4-block format with ≤5 findings. The reviewer COMPONENT works; only its auto-invocation (the #9 finding above) is missing.

## AI-DLC Artifacts

Generated under `tasks/dogfood-todo-api/aidlc-docs/` (gitignored, regenerable). Source of truth while running: `aidlc-docs/aidlc-state.md`.

## Related

- `vision.md` — Todo-API scope (intentionally tiny; exists to drive the gates)
- `tech-env.md` — Python + FastAPI + SQLite stack
- `.kiro/steering/{interface-contracts,cross-unit-smoke,change-management}.md` — the gates being verified
- `.kiro/skills/{aidlc-auto-trigger,raise-cr,memory-layering}.md` — the skills exercised
