# dogfood-todo-api — Workflow

> The workflow for this task is **AI-DLC itself**. The "stages" are not custom
> — they're the standard inception → construction → operations phases, with
> the M1 steering overrides applying as defined in `.kiro/steering/`. The
> per-row verification plan lives in `RESUME.md` → **M1 Verification Checklist**.
>
> This file exists because `new-task.sh` always creates it; for dogfood it's
> a pointer, not a process spec.

## Overview

dogfood-todo-api is a verification harness, not a development project. The "workflow" is:

1. Stand up the fork: read `vision.md` + `tech-env.md`, edit `task.yaml` to fix paths, spawn the agent.
2. Let AI-DLC drive inception → construction → operations against the steering rules.
3. Tick each row in `RESUME.md` → **M1 Verification Checklist** as the corresponding gate fires correctly.
4. Record failures in `RESUME.md` → **Findings**. Raise an issue on `wilbur-labs/kiro-workspace` for each.

## Trigger

Manual. Operator runs `kiro-cli chat --agent dogfood-todo-api` after editing `task.yaml`.

## Variables

None. All configuration lives in `task.yaml`, `vision.md`, `tech-env.md`, and the steering files.

## What's NOT in this workflow

- Production deployment — explicitly out of scope (see `vision.md` § Out of Scope).
- CI integration — dogfood is a local-only verification pass.
- Re-runnable end-to-end test — each fork's run produces different (gitignored) source under `src/`; reruns regenerate.
