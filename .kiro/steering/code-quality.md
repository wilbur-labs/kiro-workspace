# Code Quality Gate — Three-Layer Defense

Three independent layers that keep AI-generated code reviewable by a human:
**prevent** bad shapes before they are written, **detect** the semantic ones a
linter can't, and **measure** the mechanical ones objectively.

| Layer | Question | Mechanism | When |
|-------|----------|-----------|------|
| **A — Prevent** | "Don't write the bad shape." | Codegen constraints (this file) | Every code-generation step |
| **C — Detect** | "Catch the semantic problems tools miss." | `code-quality-reviewer` agent | After per-unit code-gen step 7 |
| **B — Measure** | "Hold an objective bar." | Static tooling gate | Build & Test stage |

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
run the `code-quality-reviewer` agent over the unit's generated diff.

- Agent: `.kiro/agents/code-quality-reviewer.json` (prompt:
  `.kiro/prompts/code-quality-reviewer.md`).
- It looks **only** for the four semantic classes tools miss: semantic
  duplication, cross-file duplicated validation, speculative abstraction, and
  defensive over-coding. It does not re-report lint/format/type/style — those
  are Layer B's job.
- Output is fixed at four blocks (verdict / must-fix / suggested / verification
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
- `.kiro/steering/cross-unit-smoke.md` — Part 1 smoke runs just before this gate at step 7; Part 2 is the Build & Test run Layer B measures.
- `.kiro/steering/change-management.md` — unfixed findings become CRs that flow through the phase-approval gate.
- `.kiro/templates/inputs/tech-env.md.tpl` — **Code Quality Tooling** section declares the per-project tool stack Layer B runs.
- `.kiro/aws-aidlc-rule-details/construction/code-generation.md` — upstream per-unit code-gen flow Layer A constrains and Layer C hooks after step 7.
