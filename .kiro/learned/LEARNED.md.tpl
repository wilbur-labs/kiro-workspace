# Learned — Cross-Task Knowledge Pool

This file stores **cross-project reusable lessons** — patterns, gotchas, and snippets that apply to **more than one task / project**. Loaded into every agent at spawn.

**Scope rule** (enforced by `.kiro/skills/auto-learn.md`):

| Where | What goes here |
|---|---|
| `tasks/<name>/learned.md` | Project-specific facts: schema quirks, domain rules, data shape, business logic, this codebase's conventions |
| `.kiro/learned/LEARNED.md` (this file) | Reusable across projects: tool usage, language gotchas, infrastructure patterns, framework idioms, internal-system integration recipes |
| `.kiro/shared/SHARED-CONTEXT.md` | Stable workspace-level environment (org, team, network) — not learned, just configured |
| `.kiro/steering/` | Code-generation rules, AI-DLC overrides — enforced behavior, not memory |

See `.kiro/skills/memory-layering.md` for the full decision tree.

**Promotion**: if a `tasks/<name>/learned.md` entry turns out to apply to a second task, agent should propose promoting it here (and removing from per-task to avoid drift).

---

## Entries

<!--
Format (see .kiro/skills/auto-learn.md):

### [YYYY-MM-DD] AgentName — Short title

Description (1-3 lines, key info only). Why this is cross-task: <one sentence>.

-->

<!-- example placeholder — remove once real entries arrive:

### [2026-05-23] template — Memory layering bootstrap

`.kiro/learned/LEARNED.md` is the cross-task pool; per-task learnings go in `tasks/<name>/learned.md`. agentSpawn hook loads both. Why cross-task: every project in this workspace inherits this convention.

-->

## Archive

<!-- Per .kiro/skills/auto-learn.md: entries older than 90 days move to archive/YYYY-MM.md.
Keep one-line index here. Example:
- [2026-03] 12 entries — [archive/2026-03.md](archive/2026-03.md)
-->
