# ADR — Record Why Something Is Built This Way

Playbook for capturing an **Architecture Decision Record**: the decision plus the rejected alternatives, so "why is it this way?" has a documented answer later. Full mechanism (two layers, format, how it differs from CR/learned) is in `.kiro/adr/README.md`.

Trigger this when a change **shapes a structure/mechanism**, **has a non-obvious alternative**, and **a future reader will ask "why this way"**. Not for one-off hacks or choices with no real alternative.

## Pick the layer

- Decision about the **workspace mechanism itself** (agent loading, resources, skills, memory layering, steering, CLI) → **framework layer** → `.kiro/adr/`
- Decision about **this task's underlying project** architecture (tech choice, module boundary, data flow, schema strategy) → **task layer** → `tasks/<this-agent's-task>/adr/`
- Unsure → ask the user one line.

> "This task" = the task this agent is bound to (each agent maps to one task via its `resources`). There is no global current-task pointer in kiro — the agent *is* the task.

## Listing existing ADRs

If asked to list (not create): show the number + title + Status of `.kiro/adr/*.md` (framework) and `tasks/<this-task>/adr/*.md` (task). Don't create anything.

## Creating one

1. Pick the layer (above). Target dir `<dir>` = `.kiro/adr/` or `tasks/<this-task>/adr/` (create the task dir if it doesn't exist yet).
2. Number = scan `<dir>/NNNN-*.md`, take the max + 1, 4-digit zero-padded (**never reuse a number**; `0000-template.md` doesn't count).
3. Copy `.kiro/adr/0000-template.md` to `<dir>/NNNN-<kebab-title>.md`. Fill:
   - Title (imperative), Status = `proposed`, Date = today (JST), Layer (`framework` or `task:<name>`)
   - **Context / Decision / Consequences / Alternatives considered** — fill from what the current conversation already knows, especially **Alternatives** (the paths considered-but-not-taken + why; this section is the most valuable — don't leave it a stub).
   - Cross-link related decisions with `NNNN-...` filenames.
4. Once the decision is genuinely adopted → set Status to `accepted`. **Changed your mind = write a new ADR**, set the old one's Status to `superseded by NNNN`, don't delete the old file.
5. **Framework layer** new ADR → add one line to the **Index** section of `.kiro/adr/README.md`:
   `- **NNNN** — <one-line decision> — NNNN-<file>.md`
   **Task layer** new ADR → add one line to that task's `RESUME.md` ADR pointer section.
6. Confirm in one line (number + path + layer), then continue what you were doing.

## Not an ADR

- ADR ≠ CR (scope change → `.kiro/skills/raise-cr.md`) ≠ learned (reusable snippet → `learned.md` / `LEARNED.md`). Decision test is in `.kiro/adr/README.md`.
- Don't write an ADR for a one-off hack or an obviously alternative-free trivial choice — only for decisions that shape structure, have a non-obvious alternative, and will draw a future "why this way?".
