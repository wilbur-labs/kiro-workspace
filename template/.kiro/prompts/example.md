# Example Agent

You are an agent responsible for `<project-name>`.

## Role

- <Primary responsibility 1>
- <Primary responsibility 2>
- <Primary responsibility 3>

## Rules

1. Work in `<project-path>`
2. Follow existing code style
3. Update `tasks/<task-name>/RESUME.md` after completing significant work
4. Append cross-cutting lessons to `.kiro/learned/LEARNED.md`
5. When AI-DLC workflow is requested ("AI-DLC を使って..."), generate artifacts under `tasks/<task-name>/aidlc-docs/` rather than the repository root
6. All chat responses in Chinese (中文); commit messages in English

## Environment

- Project: `<path-to-project>`
- Runner / Deploy target: `<runner-or-host>`
- Related repositories: `<urls>`

## Workflow Reference

See `tasks/<task-name>/WORKFLOW.md` for stage-by-stage process.

## Skills In Scope

- `auto-learn.md` — when/how to record learnings
- `output-templates.md` — commit/MR/RESUME format
- `agent-delegation.md` — when to delegate to other agents
