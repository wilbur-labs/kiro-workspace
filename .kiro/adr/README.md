# Architecture Decision Records (ADR)

An ADR records **why something is built the way it is** — the decision plus the alternatives that were rejected. It treats "decision amnesia": six months later (or a different agent / a different session) asking "why don't we use hooks?" has a documented answer, instead of re-litigating from scratch.

## Two layers

| Layer | Location | Records | Index / loading |
|---|---|---|---|
| **Framework** | `.kiro/adr/NNNN-*.md` (this dir) | decisions about the workspace mechanism itself | the **Index** section below, auto-loaded via every **task** agent's `resources` (`file://.kiro/adr/README.md`) |
| **Task** | `tasks/<name>/adr/NNNN-*.md` | architecture decisions of that task's **underlying project** | listed in that task's `RESUME.md` (already in `resources`) |

> **Why the index lives here and not in SHARED-CONTEXT.md**: `SHARED-CONTEXT.md` and `LEARNED.md` are gitignored user-instance files (created by `init-workspace.sh`), so a framework index there would never ship. This README is committed, so the shipped ADR index travels with the repo — and adding `file://.kiro/adr/README.md` to `resources` makes it auto-load, the kiro-native equivalent of an always-injected memory file. See ADR-0001 for why loading goes through `resources`, not hooks.

## How it differs from CR / learned (don't mix them)

| Mechanism | Answers | Example |
|---|---|---|
| **CR log** (`aidlc-docs/change-requests.md`) | should we do X (scope change) | "while we're at it, add PDF export" → creep/refine/… |
| **learned** (`learned.md` / `LEARNED.md`) | how to do Y (reusable snippet / gotcha) | "ReportLab CJK needs STSong-Light" → paste-ready recipe |
| **ADR** (this mechanism) | **why X is built this way** (decision + alternatives) | "why context loads via resources, not hooks" |

Test: a change **shapes a structure/mechanism**, **has a non-obvious alternative**, and **a future you will ask "why this way"** → write an ADR. Pure scope trade-off → CR. Pure reusable code → learned.

## Format (Nygard-lite)

Filename `NNNN-kebab-title.md` (4-digit zero-padded, monotonically increasing, **numbers are never reused**). Fixed sections:

- **Status** — `proposed` / `accepted` / `superseded by NNNN` / `deprecated`
- **Date** — YYYY-MM-DD
- **Layer** — `framework` or `task:<task-name>`
- **Context** — the problem and constraints (forces) at the time
- **Decision** — what was chosen
- **Consequences** — results and costs (what got easier / harder)
- **Alternatives considered** — what was rejected and why (**this section is the cure for decision amnesia — don't skip it**)

## Conventions

- **Changed your mind = write a new ADR**, and set the old one's Status to `superseded by NNNN` — don't delete the old file (the decision history has value).
- Scaffold a new one with the `adr` skill (`.kiro/skills/adr.md`): pick the layer, take the next number, copy `0000-template.md`.
- A new **framework** ADR → add one line to the Index below.
- A new **task** ADR → add one line to that task's `RESUME.md` ADR pointer section.

## Index (framework layer)

Machine decisions about the workspace itself. Only this index auto-loads; read full files on demand.

- **0001** — load agent context via `resources`, not agentSpawn hooks — `0001-context-via-resources-not-hooks.md`
