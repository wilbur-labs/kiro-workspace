# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **M1.2 #5** — `RESUME.md.tpl` gains a `## Current AI-DLC Stage` section (phase / stage / unit / next-unchecked) for human-readable resume; agentSpawn hook also `cat`s the machine-maintained `aidlc-docs/aidlc-state.md` so a fresh agent picks up mid-flight AI-DLC work without the user re-stating it.
- **M1.2 #6.a** — Blank `vision.md.tpl` and `tech-env.md.tpl` under `.kiro/templates/inputs/`. `new-task.sh` now copies both into `tasks/<name>/` by default (`--no-aidlc` flag opts out for ad-hoc tasks). Skeletons reuse the structure of the existing `example-minimal-*` files but ship empty for users to fill in.
- **M1.2 #6.b** — `tasks/<name>/task.yaml` as the single source of truth for `project_path`, `repo_url`, `branch_prefix`, `default_workdir`. `new-task.sh` instantiates it from `.kiro/templates/task/task.yaml.tpl`. agentSpawn hook now prints task metadata first on session start; `RESUME.md.tpl` and `prompt.md.tpl` point at `task.yaml` instead of duplicating the path inline.
- **M1.2 #7** — `prompt.md.tpl` gains three sections agents need but were previously implicit: **Persona** (role / background / values), **Decision Principles** (reversible vs irreversible action, ambiguity, obstacles, scope drift), and **Communication Style** (advisor vs executor mode, tone defaults).
- **M1.1 #3** — `scripts/init-workspace.sh`: idempotent one-time bootstrap that materializes user-instance files (`.kiro/shared/SHARED-CONTEXT.md`, `.kiro/learned/LEARNED.md`, and per-task `learned.md` for any pre-existing task) from bundled `.tpl` skeletons. Run once after cloning the template, and again when upgrading older workspaces.
- **M1.1 #3** — `.kiro/shared/SHARED-CONTEXT.md.tpl` and `.kiro/learned/LEARNED.md.tpl` skeletons shipped with the template. The instantiated `.md` files remain gitignored (user-instance data).
- **M1.1 #11** — Per-task knowledge pool: `tasks/<name>/learned.md`, auto-created by `new-task.sh` from a new `.kiro/templates/task/learned.md.tpl`. Holds project-specific facts (schema, domain quirks) that should not pollute the cross-task pool.
- **M1.1 #11** — `.kiro/skills/memory-layering.md`: decision tree mapping each kind of knowledge to its layer (per-task / cross-task / shared-context / steering) with concrete examples and anti-patterns.
- **M1.1 #11** — agentSpawn hook now loads `tasks/<name>/learned.md` in addition to cross-task `LEARNED.md`, and emits an explicit "run `scripts/init-workspace.sh`" hint when workspace-level skeletons are missing (replacing the previous silent failure).
- **M1.1 #8** — `scripts/update-aidlc.sh`: `--dry-run` to preview, `--force` to override, automatic timestamped backup at `.kiro/.aidlc-backup-<ts>/`, and a default-refuse path when local edits diverge from the target upstream release.

### Changed

- **M1.2 #6.b** — `RESUME.md.tpl` Key Info section now points to `task.yaml` instead of duplicating `project_path` inline; `prompt.md.tpl` Environment section likewise. Eliminates two prose-copies of the same fact.
- **M1.2 #6.a** — Quick Start in `README.md` no longer hand-copies `example-minimal-*.md` into `vision.md` / `tech-env.md` — `new-task.sh` handles it. (Also collapses a duplicate step 4/5 left over from the M1.1 README rewrite.)
- **M1.2 docs** — README.md / AGENTS.md: documented `task.yaml`, the `--no-aidlc` flag, `Current AI-DLC Stage` section, and prompt persona/principles/style.
- **M1.1 #11** — `.kiro/skills/auto-learn.md`: added an applicability-filter decision tree that routes learnings to the correct layer before write, plus a promotion flow (per-task → cross-task with a mandatory "Why cross-task" justification line). Discourages copy-paste duplication across layers.
- **M1.1 #11** — README.md / AGENTS.md: documented the memory-layering model, the `init-workspace.sh` bootstrap step, and the per-task `learned.md` convention.

### Deferred

- **M1.2 #6.c** — `agent.json.tpl` `toolsSettings.allowedPaths` for fs scope restriction is **deferred**. Audit gap surfaced: kiro-cli docs use tool names `write` / `shell` / `aws` + MCP tools and glob `allowedPaths` syntax, but the repo's `example.json` uses `fs_read` / `fs_write` / `execute_bash` (Amazon Q Developer CLI naming). Without a local kiro-cli to smoke-test the actual schema, picking either form risks producing an `agent.json` that won't load. To be revisited when a kiro-cli environment is available.
