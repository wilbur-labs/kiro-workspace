# {{TASK_NAME}} — Session Recovery

> Read this file at session start to understand current state.
> Last updated: {{DATE}}

## Current State

- Branch: `feat/xxx`
- Status: Just started

## Current AI-DLC Stage

> Human-readable pointer to where AI-DLC paused. `aidlc-docs/aidlc-state.md`
> (the machine-maintained state file) is loaded at spawn via the agent's
> `resources` list — keep this section short, that state file is the source of
> truth while AI-DLC is running.

- Phase: `<inception | construction | operations | n/a>`
- Stage: `<requirements-analysis | application-design | code-generation | build-and-test | …>`
- Unit: `<unit-name or n/a>`
- Next unchecked step: `<one line — what to do when resuming>`

## Next Steps

1. (TODO)

## Key Info

> Paths and repo coordinates live in `tasks/{{TASK_NAME}}/task.yaml` (single
> source of truth). Don't duplicate them here — read the YAML instead.

- Related MR: <url>

## AI-DLC Artifacts

If using AI-DLC, artifacts live under `tasks/{{TASK_NAME}}/aidlc-docs/`.
Source of truth for in-progress workflow: `aidlc-docs/aidlc-state.md`.

## ADR (task layer)

Architecture decisions for this task's underlying project live in
`tasks/{{TASK_NAME}}/adr/NNNN-*.md`. Index them here (one line each) so they
surface at spawn — this RESUME is in the agent's `resources`, the adr/ files are
not. Scaffold with the `adr` skill (`.kiro/skills/adr.md`). Framework-mechanism
decisions go to `.kiro/adr/` instead.

- (none yet)
