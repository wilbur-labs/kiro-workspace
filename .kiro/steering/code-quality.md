# Code Quality Gate — Three-Layer Defense

Three independent layers that keep AI-generated code reviewable by a human:
**prevent** bad shapes before they are written, **detect** the semantic ones a
linter can't, and **measure** the mechanical ones objectively.

| Layer | Question | Mechanism | When |
|-------|----------|-----------|------|
| **A — Prevent** | "Don't write the bad shape." | Codegen constraints (this file) | Every code-generation step |
| **C — Detect** | "Catch the semantic problems tools miss." | `code-quality-reviewer` agent | After per-unit code-gen step 7 |
| **B — Measure** | "Hold an objective bar." | Static tooling gate | Build & Test stage |

Plus one **independent** checkpoint that none of A/B/C can be, because they all
run inside the primary model's own session: **codex pre-commit review** — a
different model, no session context, run before every commit. See "Independent
External Review" below and `.kiro/adr/0002-review-outsourced-to-codex.md`.

This file is a steering **override** on top of
`.kiro/aws-aidlc-rule-details/construction/code-generation.md`. Upstream files
under `.kiro/aws-aidlc-rule-details/` are NOT modified.

## Why this exists

AI codegen has a characteristic failure profile that ordinary linting does not
catch: it writes code that is *locally plausible* but globally redundant or
over-built. The three recurring shapes are **semantic duplication** (re-implementing
a rule that already has an owner), **speculative abstraction** (a factory/manager
for a single call site), and **defensive over-coding** (null-guards and
swallowed catches around invariants that already hold). None of these are syntax
errors; a formatter and a type-checker pass them straight through. They surface
later as drift, dead indirection, and silent failures.

The single principle under all three layers: **make the model prove there is no
better home in the existing code before it is allowed to add anything new.**

---

## Layer A — Codegen Constraints (Prevent)

These rules apply during the code-generation stage, for every unit. They are
the cheapest layer — they shape the output before it exists.

```markdown
## Code Quality Constraints for AI Codegen

- Prefer reuse over creation. Before adding a function, class, schema, validator, abstraction, or dependency, search for existing equivalents and extend the closest existing pattern.
- Keep changes minimal and task-scoped. Do not introduce new architecture, caching, retries, queues, permissions, plugins, or configuration systems unless explicitly required.
- Validate once at trust boundaries. Do not duplicate validation across controller/service/repository/client layers; pass typed/validated data inward.
- Avoid speculative abstractions. Do not create interfaces, factories, managers, adapters, registries, or strategy layers for a single use case.
- Follow existing error-handling boundaries. Do not add blanket try/catch, swallow errors, or wrap every error unless the surrounding code does so.
- Do not add new dependencies without verification. Confirm package name, version, project package manager, and existing alternatives first.
- Never hallucinate APIs. If an API, method, field, config key, or package is not present in code or official docs, treat it as unavailable.
- Complete the edit graph. Update all affected call sites, types, tests, and docs needed for the change to compile and behave consistently.
- No placeholders in implemented code. Do not leave pseudocode, commented-out attempts, or "existing code here" markers.
- Verify with the narrowest relevant tests/checks and report exactly what was and was not run.
```

Each rule maps to a concrete anti-pattern:

| Rule | Covers |
|------|--------|
| Prefer reuse | hallucinated abstractions, duplicated validation, duplicated implementation |
| Validate once | defensive over-coding, cross-file validation drift |
| Avoid speculative abstractions | hallucinated abstractions, over-engineering |
| No new deps without verification | package hallucination, supply-chain risk |
| Existing error boundaries | defensive over-coding, swallowed exceptions |
| Complete the edit graph | incomplete generation, lazy coding |
| Never hallucinate APIs | false confidence, non-existent surface |
| No placeholders | incomplete generation |

---

## Layer C — Reviewer Gate (Detect)

After per-unit code generation, **once Part 1 cross-unit smoke
(`.kiro/steering/cross-unit-smoke.md`) has passed and before step 7 is closed**,
the primary agent MUST run the `code-quality-reviewer` agent over the unit's
generated diff. This is a gate, not a reminder — it must not depend on the agent
remembering to do it.

**How to invoke (this is the part that makes it executable, not just a rule):**

- Use the `use_subagent` tool (blocking mode) to delegate to `code-quality-reviewer`
  — see `.kiro/skills/agent-delegation.md`. Pass the unit name + the list of
  files generated in this unit; do NOT dump full context (the reviewer reads the
  files itself).
- `use_subagent` is a kiro **builtin** tool — it does not need to be declared in
  the agent's `tools` list (an earlier revision guessed a non-existent `subagent`
  name). The blocker is never a missing tool; it is forgetting to read this gate
  at all. These construction gates live in this steering file (auto-loaded at
  spawn by the kiro-cli rules engine). NOTE: an earlier `agentSpawn`-hook workaround
  that re-echoed the gates is void — the new Kiro CLI does not inject hook stdout
  into the model context (context comes from `resources` + steering, not hooks).
- Reviewer config: `.kiro/agents/code-quality-reviewer.json` (prompt:
  `.kiro/prompts/code-quality-reviewer.md`).

**Self-check (mandatory).** Before closing step 7 the agent asks itself: "did the
reviewer actually run, and did I act on its verdict?" If the reviewer could not be
invoked for any reason (missing tool, missing agent, error), the agent **raises a
blocker CR per `.kiro/skills/raise-cr.md` and does NOT close step 7.** Silently
skipping a gate it cannot execute is the exact failure this rule exists to prevent
— a gate that only runs when the agent remembers it is not a gate.

The reviewer:

- looks **only** for the four semantic classes tools miss: semantic duplication,
  cross-file duplicated validation, speculative abstraction, and defensive
  over-coding. It does not re-report lint/format/type/style — those are Layer B's job.
- emits a fixed four-block output (verdict / must-fix / suggested / verification
  checklist), capped at 5 findings.

**Gate behavior:**

| Verdict | Effect on step 7 |
|---------|------------------|
| `Request changes` (≥1 Blocker) | **Blocks** closing step 7. |
| `Approve with comments` (High/Medium only) | Step 7 may close; High findings must each be either fixed or converted to a CR. |
| `Approve` | Step 7 closes. |

Findings that the team decides not to fix immediately do not silently vanish —
they route through the change-management gate
(`.kiro/steering/change-management.md`) as `bug` / `clarify` / `refine` CRs, so
they remain visible at phase-approval time.

**A prevents, C detects — they must not double-enforce.** Layer A constrains the
model while writing; Layer C inspects the result. The reviewer assumes Layer A
was in force and looks for what slipped through, rather than re-stating the same
rules.

---

## Layer B — Tooling Gate (Measure)

The objective bar, enforced at the Build & Test stage (which
`.kiro/steering/cross-unit-smoke.md` Part 2 already requires to be a real test
run). The concrete tool stack per language lives in the project's `tech-env.md`
→ **Code Quality Tooling** section; this gate consumes whatever that section
declares.

**Default thresholds** (per function/method unless noted):

| Metric | Recommended | Review | Fail |
|--------|------------:|-------:|-----:|
| Cognitive complexity | ≤ 15 | 16–25 | > 25 |
| Cyclomatic complexity | ≤ 10 | 11–20 | > 20 |
| Duplication (new code) | ≤ 3% | 3–10% | > 10% |
| Python (radon/xenon) | A–B | C | `xenon --max-absolute B` fails on > B |

Cognitive complexity is preferred over cyclomatic where both are available — it
tracks *how hard the code is to read*, not just path count.

**Strictness strategy: PR/new code strict, legacy lenient.** New code must clear
the gate; existing code is held to "don't make it worse" (ratchet the
whole-project ratio down over time, don't fail the build on inherited debt). This
is the only way the gate lands on a real codebase without a wall of day-one
failures. Start at the thresholds above; tighten after ~6 months of real data
rather than guessing stricter numbers up front.

---

## Independent External Review — Codex (pre-commit)

Layers A/C/B are all executed by the primary model inside its own session, so
they share its blind spots — a same-model reviewer tends to bless the shapes the
author found natural. The cure is a **different** model that never saw this
session: **codex**.

**Hard rule: any code change, before `git commit`, runs codex review.** This
includes changes to the workspace framework itself (steering, skills, agent
JSON, scripts) — the framework is not exempt from its own gate.

- Run `bash scripts/codex-review.sh <repo>` (default scope `--uncommitted`).
  Full playbook — repo discovery, triage, reporting — is in
  `.kiro/skills/codex-review.md`.
- **Complements Layer C, does not replace it.** Layer C runs per-unit
  mid-construction on the four semantic classes; codex runs at commit time over
  the whole change with independent eyes. Both run — don't drop one for the other.
- Order: ① primary agent runs tests and they pass → ② codex review → ③ triage
  every finding (fix real bugs and re-run tests / reject false positives with a
  one-line reason / escalate genuine disagreements to the user) → ④ commit only
  once clean.
- Tests are **not** outsourced — the primary agent runs them. Codex is review
  only and never substitutes for tests.

Why external and not just "a second internal reviewer agent": an independent
model with no session context catches what the primary model rationalizes as
correct. This is the same principle behind separating *prevent* (A) from
*detect* (C) — different vantage points catch different failures — taken one step
further to a different vantage *model*.

## Success Metric — Adoptability, not finding count

The gate is optimized for **the fraction of findings a human can decide on and
accept within five minutes**, not for the number of problems surfaced. A
reviewer that emits 30 low-confidence nits trains people to ignore it; one that
emits 2 well-evidenced Blockers gets acted on.

Operational consequences (enforced in the reviewer prompt's output rules):

- **Say less by default.** Over 5 findings → keep only Blocker/High; nits are
  never emitted.
- **Evidence first.** A finding with no cross-file evidence does not enter the
  main list — it goes to "needs confirmation".
- Track adoptability over time (findings acted on ÷ findings raised). If it
  drops, the fix is *fewer, better-evidenced* findings — never *more* findings.

## Anti-Patterns

- **Double-enforcing A in C** — the reviewer re-listing the codegen constraints
  as findings. A is prevent, C is detect; the reviewer reports what slipped past
  A, not the rules themselves.
- **Failing the build on legacy debt** — day-one wall of failures kills adoption.
  Gate new code; ratchet the rest.
- **Optimizing finding count** — "the reviewer found 24 issues" is a warning
  sign, not a win. Optimize adoptability.
- **Treating tool metrics as the whole story** — Layer B catches size,
  duplication, and complexity; it cannot see semantic duplication or speculative
  abstraction. That is exactly why Layer C exists.
- **Letting High findings evaporate** — anything not fixed now becomes a CR, or
  it will silently ship.

## Related

- `.kiro/agents/code-quality-reviewer.json` + `.kiro/prompts/code-quality-reviewer.md` — the Layer C reviewer.
- `.kiro/skills/codex-review.md` + `scripts/codex-review.sh` — the independent external (codex) pre-commit gate; `.kiro/adr/0002-review-outsourced-to-codex.md` records why.
- `.kiro/steering/cross-unit-smoke.md` — Part 1 smoke runs just before this gate at step 7; Part 2 is the Build & Test run Layer B measures.
- `.kiro/steering/change-management.md` — unfixed findings become CRs that flow through the phase-approval gate.
- `.kiro/templates/inputs/tech-env.md.tpl` — **Code Quality Tooling** section declares the per-project tool stack Layer B runs.
- `.kiro/aws-aidlc-rule-details/construction/code-generation.md` — upstream per-unit code-gen flow Layer A constrains and Layer C hooks after step 7.
