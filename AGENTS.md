# AGENTS.md

> Entry point for AI coding agents (Codex, Claude Code, Kiro CLI, etc.) working in this workspace.
> Human-readable overview is in [README.md](README.md).

## Project overview

This is a **multi-agent workspace** for managing several projects under a single kiro-cli setup.

- Each project has its own agent (`.kiro/agents/<name>.json`) and task directory (`tasks/<name>/`).
- A shared context layer (`.kiro/shared/`, `.kiro/learned/`, `.kiro/skills/`) carries information across agents.
- The [AI-DLC](https://github.com/awslabs/aidlc-workflows) v0.1.8 methodology is pre-installed under `.kiro/steering/` and `.kiro/aws-aidlc-rule-details/`.

## Repository structure

```text
.kiro/
├── steering/                          # Auto-loaded rules (AI-DLC + locale override)
│   ├── aws-aidlc-rules/core-workflow.md
│   └── locale-override.md             # Forces Chinese interaction + JST + per-task aidlc-docs
├── aws-aidlc-rule-details/            # AI-DLC detail rules (loaded on demand)
├── agents/                            # Per-project agent definitions
├── prompts/                           # Per-agent system prompts (referenced via file://)
├── shared/SHARED-CONTEXT.md{,.tpl}    # Workspace env (.tpl shipped, .md created by init-workspace.sh)
├── learned/LEARNED.md{,.tpl}          # Cross-task knowledge pool (.tpl shipped, .md created by init-workspace.sh)
├── skills/                            # Cross-project reusable instruction modules
│   ├── auto-learn.md                  # Capture rules + layer decision tree
│   └── memory-layering.md             # Where each kind of knowledge belongs
├── templates/
│   ├── task/                          # Scaffolding for new tasks (used by new-task.sh)
│   │   ├── task.yaml.tpl              # Structured metadata (project_path, repo_url, branch_prefix)
│   │   ├── learned.md.tpl             # Per-task knowledge pool
│   │   ├── RESUME.md.tpl              # Includes Current AI-DLC Stage section
│   │   └── prompt.md.tpl              # Persona / decision principles / communication style
│   └── inputs/                        # AI-DLC Vision + Tech-Env templates and guides
│       ├── vision.md.tpl              # Blank vision skeleton (copied by new-task.sh)
│       └── tech-env.md.tpl            # Blank tech-env skeleton (copied by new-task.sh)
└── settings/

scripts/
├── init-workspace.sh                  # Bootstrap user-instance files from .tpl (one-time after clone)
├── new-task.sh                        # Scaffold a new task in one command
└── update-aidlc.sh                    # Update AI-DLC rules from GitHub release

tasks/<name>/
├── task.yaml                          # Structured metadata — single source of truth for paths/repo
├── RESUME.md                          # Cross-session human-readable summary (+ Current AI-DLC Stage)
├── WORKFLOW.md                        # Process definition
├── learned.md                         # Per-task knowledge pool (project schema, domain quirks)
├── vision.md                          # AI-DLC Vision document (skip with new-task.sh --no-aidlc)
├── tech-env.md                        # AI-DLC Tech-Env document (skip with new-task.sh --no-aidlc)
└── aidlc-docs/                        # AI-DLC artifacts (gitignored, source of truth while running)
```

## Which docs to read by task type

- **Adding a new project** → run `scripts/new-task.sh <name> <project-path>`, then edit the generated files
- **AI-DLC workflow questions** → `.kiro/skills/aidlc-usage-tips.md`
- **Starting an AI-DLC workflow for a new project** → `.kiro/templates/inputs/README.md`
- **Cross-agent collaboration** → `.kiro/skills/agent-delegation.md`
- **Recording a project-specific lesson** (schema, domain, business quirk) → append to `tasks/<name>/learned.md`
- **Recording a cross-task lesson** (tool / framework / internal-system recipe) → append to `.kiro/learned/LEARNED.md` with a "Why cross-task" line
- **Deciding where a lesson belongs** → read `.kiro/skills/memory-layering.md`
- **Code style / output formats** → `.kiro/skills/output-templates.md`
- **Delegating small tasks to local LLMs** → `.kiro/skills/delegate-to-local-llm.md`

## Setup commands

```bash
# Lint markdown files (matches awslabs/aidlc-workflows style)
npx markdownlint-cli2 "**/*.md"

# Auto-fix where possible
npx markdownlint-cli2 --fix "**/*.md"

# Install pre-commit hooks (optional)
pre-commit install

# Bootstrap user-instance files (one-time, idempotent)
./scripts/init-workspace.sh

# Scaffold a new task (creates task.yaml + RESUME/WORKFLOW/learned + vision/tech-env)
./scripts/new-task.sh <task-name> <project-path>

# Same, but skip AI-DLC inputs (vision.md / tech-env.md) for ad-hoc tasks
./scripts/new-task.sh --no-aidlc <task-name> <project-path>
```

## Rules for agents

1. **Language**: Chat in Chinese (中文). Commit messages in English. See `.kiro/steering/locale-override.md`.
2. **State management**: After significant work, update `tasks/<name>/RESUME.md` (the `## Current AI-DLC Stage` section for in-progress AI-DLC workflows). Don't fabricate state — read the file first.
2a. **Paths and repo coordinates**: read from `tasks/<name>/task.yaml`. Don't hard-code `project_path` in prompts or RESUME — it lives in one place.
3. **AI-DLC artifacts**: Generate under `tasks/<name>/aidlc-docs/`, NOT repository root.
4. **Learning**: Run the layer decision tree in `.kiro/skills/memory-layering.md` before writing. Project-specific → `tasks/<name>/learned.md`. Cross-task reusable → `.kiro/learned/LEARNED.md` (with "Why cross-task" line). Follow `.kiro/skills/auto-learn.md` archival rules.
5. **Hooks**: Spawn hooks load RESUME, SHARED-CONTEXT, per-task learned, cross-task LEARNED. Don't duplicate that content in chat.
6. **Cross-agent work**: Use `subagent` tool with rules in `.kiro/skills/agent-delegation.md`.
7. **Vibe coding is forbidden** — when AI-DLC is in use, update design docs first, then regenerate code. See `aidlc-usage-tips.md`.

## Code style

- Markdown only in this template (no production code lives here).
- Markdown lint config: `.markdownlint-cli2.yaml` (MD013/MD024/MD033/MD036 disabled to match AI-DLC document style).
- Commit messages: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).

## License

MIT
