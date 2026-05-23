# Change Management — CR Log & Phase Gate

AI-DLC's MVP boundary is described in `.kiro/templates/inputs/vision-document-guide.md` and the per-task `vision.md`. The rule engine does NOT enforce that boundary on its own. This file is the enforcement layer.

**Why this exists:** during construction / debug / e2e it is normal for stakeholders (or the agent itself) to suggest "顺手加 X" / "为啥不也 Y". Without a gate, those suggestions accumulate silently and the final artifact drifts away from the vision that was approved at inception.

## Five CR Types

Every change suggestion that surfaces AFTER a phase is approved must be classified as exactly one of:

| Type       | Definition                                                                  | Drift? | Action                                                                                   |
|------------|-----------------------------------------------------------------------------|--------|------------------------------------------------------------------------------------------|
| `bug`      | Implementation fails to match the approved design/requirements              | No     | Fix design (if design was wrong) or code (if design was right). Regenerate as needed.    |
| `clarify`  | Requirement was ambiguous; new info refines understanding                   | No     | Update design.md only. Do NOT touch vision.md / requirements.md.                         |
| `refine`   | Within-MVP detail tweak (renaming, ordering, micro-feature inside scope)    | No     | Update design.md. Vision unchanged.                                                      |
| `creep`    | New requirement beyond the approved MVP                                     | **Yes**| User MUST pick: (a) accept → update vision.md + requirements.md → re-approve those phases first, (b) backlog to a later release, (c) reject. |
| `cut`      | Removing scope ("we decided we don't need X after all")                     | **Yes**| User MUST update vision.md to reflect the new scope. Then re-approve.                    |

When in doubt between `refine` and `creep`: if you would not have been able to write a single-line acceptance test for it from the original vision.md, it is `creep`.

## CR Log Format

Each task tracks its CRs in `tasks/<task-name>/aidlc-docs/change-requests.md`. The file is created by `scripts/new-task.sh` from `.kiro/templates/task/change-requests.md.tpl`.

Entry schema:

| Column         | Required | Notes                                                                                |
|----------------|----------|--------------------------------------------------------------------------------------|
| ID             | yes      | `CR-N` (monotonically increasing)                                                    |
| When           | yes      | ISO date or `YYYY-MM-DD HH:MM JST` if precision matters                              |
| Phase / Stage  | yes      | e.g. `construction / unit-auth code-gen`                                             |
| Source         | yes      | `user` / `agent` / `reviewer` / `oncall`                                             |
| Description    | yes      | One sentence — what was suggested, in the requester's words                          |
| Type           | yes      | One of: `bug` / `clarify` / `refine` / `creep` / `cut` / `UNCLASSIFIED` (before triage) |
| Status         | yes      | `OPEN` / `DECIDED` / `DONE`                                                          |
| Decision       | when DECIDED | `accept` / `backlog` / `reject` (creep/cut only) or `apply` (bug/clarify/refine)  |
| Propagated To  | when DONE | Comma-separated list of file(s) updated, e.g. `vision.md L42, requirements.md L18`   |

## Phase Approval Gate

Before approving any phase (inception / construction / operations), the agent MUST:

1. Read `tasks/<task-name>/aidlc-docs/change-requests.md`.
2. List every CR with status ≠ `DONE`.
3. If any are `UNCLASSIFIED` → block, force classification.
4. If any are `OPEN` → block, force decision.
5. If any `DECIDED` as `creep` with `accept` but **Propagated To is empty** → block. The user must update vision.md / requirements.md AND re-approve the upstream phase (inception) BEFORE the current phase can be approved.
6. Only when every CR is `DONE` or `DECIDED` with `Propagated To` filled → proceed with normal phase approval.

The approval prompt text MUST list the CR count and IDs explicitly, e.g.:

```
Construction phase ready to approve.
CR status: 3 DONE, 1 DECIDED (CR-4, propagated to vision.md L42), 0 OPEN.
Proceed? (y/n)
```

If there are blocking CRs:

```
Cannot approve construction — 2 OPEN CRs need classification + decision:
- CR-5: "Export to CSV" (UNCLASSIFIED)
- CR-7: "Add audit log" (OPEN, classified as creep, no decision yet)
Run the raise-cr skill to triage, then re-request approval.
```

## Standing-Rule Self-Check

Before producing any design document or generating any code, the agent MUST ask itself:

> "Does what I am about to produce match the approved vision.md and requirements.md?
> If I'm about to introduce a field, an endpoint, a screen, or a behavior that is not
> in the approved scope — is this a `refine` or a `creep`?"

If `creep`: STOP, raise a CR via `.kiro/skills/raise-cr.md`, do not silently expand scope.

If `refine`: proceed, but mention it in the next CR-log entry or design-update note so the audit trail is complete.

## Promotion to Vision (creep → accept)

When the user accepts a `creep`:

1. The agent updates `tasks/<name>/vision.md` first (adding the new feature to MVP scope).
2. Then `tasks/<name>/aidlc-docs/inception/requirements-analysis/requirements.md` (or equivalent) to add the corresponding requirement.
3. Then re-runs inception approval just for the changed sections.
4. Only then is the CR's `Propagated To` field filled in and Status set to `DONE`.
5. Only then may construction continue.

This is the cost of accepting a creep. Surfacing this cost is the point of the gate.

## Anti-Patterns

- **Silent absorption** — "I'll just add this small thing, no need for a CR." → If you find yourself thinking this, it's a CR.
- **Batching without triage** — Collecting 12 OPEN CRs and approving construction "to keep moving." The gate exists to prevent this.
- **Updating design.md instead of vision.md for a creep** — design.md is downstream. Promotion must start at vision.md.
- **Treating `clarify` as a free pass for scope changes** — If new info changes WHAT the system does (not just how), it's `refine` at best, `creep` at worst, never `clarify`.

## Related

- `.kiro/skills/raise-cr.md` — how to capture a CR mid-flow without breaking the conversation.
- `.kiro/templates/task/change-requests.md.tpl` — per-task CR-log skeleton.
- `.kiro/templates/inputs/vision-document-guide.md` — the source-of-truth scope document.
