# 0001. Load agent context via `resources`, not agentSpawn hooks

- **Status**: accepted
- **Date**: 2026-07-06
- **Layer**: framework

## Context

Every agent needs its task/workspace context (task.yaml, RESUME, WORKFLOW, learned, CR-log, SHARED-CONTEXT, LEARNED, skills) loaded at spawn. The original design put this in each `agent.json`'s **`agentSpawn` hook** — a shell command (`cat ./tasks/<name>/RESUME.md`, etc.) that runs when the agent starts, on the assumption its stdout is fed into the model context.

While standardizing the agents (task S1), a live two-round test on the current Kiro CLI showed that assumption is **false**: a `task.yaml` referenced only through an `agentSpawn` hook never appeared in the model's context; the **same file listed under the agent's `resources` (`file://…`) did** appear. The new Kiro CLI does not pipe agentSpawn hook stdout into the model context.

This is a load-bearing discovery: the entire "centralize load logic into one `kiro-session-start.sh` hook" direction (planned as K1) was built on the wrong mechanism and would have loaded nothing.

## Decision

- Load all spawn-time context through the agent's **`resources`** list (`file://` for files, `skill://` for skill modules). Not through `agentSpawn` hooks.
- Missing `file://` resources are silently skipped, so listing a not-yet-created file (e.g. `vision.md` for an ad-hoc task) is safe and future-proof.
- To change what an agent loads at spawn, edit its `resources` array — there is no shared session-start script to touch.
- Deleted `kiro-session-start.sh`; removed the `agentSpawn` hooks from all agents and the task template.

## Consequences

- **Load logic is per-agent, in the `agent.json` `resources` array** — no single choke point. Adding a workspace-wide resource (like this ADR index) means editing every agent's `resources`, not one script. Accepted cost; the task template (`agent.json.tpl`) carries the canonical list so new tasks inherit it.
- Any doc that described "agentSpawn hook cats X" was **wrong** and had to be corrected (AGENTS.md, README, memory-layering, auto-learn, code-quality, RESUME/SHARED-CONTEXT templates, dogfood prompt).
- This ADR mechanism itself relies on the decision: the framework ADR index ships in `.kiro/adr/README.md` and auto-loads because that file is in every **task** agent's `resources` (special-purpose agents like `code-quality-reviewer` keep a minimal resource list and are intentionally excluded).

## Alternatives considered

- **Centralize load logic in a shared `agentSpawn` hook script (`kiro-session-start.sh`)** — the original K1 plan. Rejected: **empirically the hook output is not injected into context**, so it loads nothing. This is not a preference; it's a capability limit of the current Kiro CLI.
- **Duplicate the context inline in each agent's `prompt`** — rejected: prompts are static; task state (RESUME) changes every session, so it would go stale immediately and bloat the prompt.
- **Keep hooks and also add resources (belt-and-suspenders)** — rejected: dead code that misleads the next maintainer into thinking hooks work. Removed the hooks outright.
