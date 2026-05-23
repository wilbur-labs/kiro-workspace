# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **M1.1 #3** — `scripts/init-workspace.sh`: idempotent one-time bootstrap that materializes user-instance files (`.kiro/shared/SHARED-CONTEXT.md`, `.kiro/learned/LEARNED.md`, and per-task `learned.md` for any pre-existing task) from bundled `.tpl` skeletons. Run once after cloning the template, and again when upgrading older workspaces.
- **M1.1 #3** — `.kiro/shared/SHARED-CONTEXT.md.tpl` and `.kiro/learned/LEARNED.md.tpl` skeletons shipped with the template. The instantiated `.md` files remain gitignored (user-instance data).
- **M1.1 #11** — Per-task knowledge pool: `tasks/<name>/learned.md`, auto-created by `new-task.sh` from a new `.kiro/templates/task/learned.md.tpl`. Holds project-specific facts (schema, domain quirks) that should not pollute the cross-task pool.
- **M1.1 #11** — `.kiro/skills/memory-layering.md`: decision tree mapping each kind of knowledge to its layer (per-task / cross-task / shared-context / steering) with concrete examples and anti-patterns.
- **M1.1 #11** — agentSpawn hook now loads `tasks/<name>/learned.md` in addition to cross-task `LEARNED.md`, and emits an explicit "run `scripts/init-workspace.sh`" hint when workspace-level skeletons are missing (replacing the previous silent failure).
- **M1.1 #8** — `scripts/update-aidlc.sh`: `--dry-run` to preview, `--force` to override, automatic timestamped backup at `.kiro/.aidlc-backup-<ts>/`, and a default-refuse path when local edits diverge from the target upstream release.

### Changed

- **M1.1 #11** — `.kiro/skills/auto-learn.md`: added an applicability-filter decision tree that routes learnings to the correct layer before write, plus a promotion flow (per-task → cross-task with a mandatory "Why cross-task" justification line). Discourages copy-paste duplication across layers.
- **M1.1 #11** — README.md / AGENTS.md: documented the memory-layering model, the `init-workspace.sh` bootstrap step, and the per-task `learned.md` convention.
